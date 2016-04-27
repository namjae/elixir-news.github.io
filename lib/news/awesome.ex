defmodule News.Github.Awesome do

  use Timex

  @client Tentacat.Client.new(%{access_token: Application.get_env(:news, :github_access_token)})
  @owner "elixir-news"
  @repo "elixir-news.github.io"
  @awesome_file "_posts/2016-04-09-awsome-elixir.markdown"
  @header """
  ---
  layout: post
  title:  "Awesome Elixir Collection"
  date:   2016-04-09 20:00:11
  ---

  Self-synchronizing from [awesome-elixir](https://github.com/h4cc/awesome-elixir) everyday.

  A curated list of amazingly awesome Elixir libraries, resources, and shiny things inspired by [awesome-php](https://github.com/ziadoz/awesome-php).

  """

  @source_owner "h4cc"
  @source_repo "awesome-elixir"
  @source_file "README.md"
  @last_source "latest_awesome_sha.md"

  def update do
    %{"content" => content, "sha" => sha} = fetch_source_file
    if need_update?(sha) do
      content
      |> restructuring_content
      |> upload_file
      File.write(@last_source, sha)
    end
  end

  def fetch_source_file do
    Tentacat.Contents.find(@source_owner, @source_repo, @source_file)
  end

  defp need_update?(sha) do
    case File.read(@last_source) do
      {:ok, ^sha} -> false
      _ -> true
    end
  end

  def restructuring_content(content) do
    file = Tentacat.Contents.find(@owner, @repo, @awesome_file, @client)
    new_content = content |> :base64.decode |> update_content
    %{sha: file["sha"], path: file["path"], message: commit_log, content: :base64.encode(new_content)}
  end

  defp update_content(content) do
    @header <> String.slice(content, 447..-1)
  end

  defp upload_file(body) do
    Tentacat.Contents.update(@owner, @repo, @awesome_file, body, @client)
  end

  defp commit_log do
    Timex.DateTime.now("Asia/Shanghai") |> Timex.format!("%FT%T%:z", :strftime)
  end

end

