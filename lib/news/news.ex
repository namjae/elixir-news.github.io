defmodule News.Github.News do

  use Timex

  @client Tentacat.Client.new(%{access_token: Application.get_env(:news, :github_access_token)})
  @owner "elixir-news"
  @repo "elixir-news.github.io"
  @header "---\nlayout: post\ntitle:  \"Awesome Elixir\"\ndate:   2016-04-09 00:00:11\n\n---\n## "
  @news_file "_posts/2016-04-09-news.markdown"

  def update do
    issues = find_today_issues

    issues
    |> restructuring_issues
    |> upload_file

    close_issues(issues)
  end

  def restructuring_issues([]), do: :ok
  def restructuring_issues(issues) do
    new_news = joint_news(issues)
    file = Tentacat.Contents.find(@owner, @repo, @news_file, @client)
    content = file["content"] |> :base64.decode
    new_content = update_content(content, new_news)
    File.write("latest.news.markdown", new_content)
    %{sha: file["sha"], path: file["path"], message: commit_log, content: :base64.encode(new_content)}
  end

  defp update_content(content, new_news) do
    old_items = String.slice(content, 78..-1)
    week = week
    if String.starts_with?(old_items, week) do
      old_items = String.slice(old_items, 9..-1)
      @header <> week <> "\n\n" <> new_news <> old_items
    else
      @header <> week <> "\n\n" <> new_news <> "\n## "<> old_items
    end
  end

  defp joint_news(issues) do
    issues
    |> Enum.map(fn(issue) ->
      [url|text] = String.split(issue["body"], "\r\n\r\n")
      text = text |> List.to_string |> String.rstrip(?\n)
      date = String.slice(issue["created_at"], 0, 10)
      %{body: issue["body"],
        title: issue["title"],
        text: text,
        url: url,
        date: date,
        created_at: issue["created_at"]}
    end)
    |> Enum.sort_by(fn(x) -> x.created_at end)
    |> Enum.reduce("", fn(issue, acc) ->
      "* [#{issue.title}](#{issue.url}) - #{issue.text} (#{issue.date})\n" <> acc
    end)
  end

  def find_today_issues do
    {:ok, time} = Timex.DateTime.local |> Timex.beginning_of_day |> Timex.format("{ISO}")
    filters = %{state: "open", since: time}
    Tentacat.Issues.filter(@owner, @repo, filters, @client)
  end

  defp upload_file(body) do
    Tentacat.Contents.update(@owner, @repo, @news_file, body, @client)
  end

  def close_issues(issues) do
    Enum.each(issues, fn(issue) ->
      Tentacat.Issues.edit(@owner, @repo, issue["number"], %{state: "closed"}, @client)
    end)
  end

  defp week do
    {year, week} = :calendar.iso_week_number
    "#{year}-#{week}"
  end

  defp commit_log do
    Timex.DateTime.now("Asia/Shanghai") |> Timex.format!("%FT%T%:z", :strftime)
  end

end

