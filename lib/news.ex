defmodule News do
  use Application
  import Supervisor.Spec

  def start(_type, _args) do
    children = [
      worker(News.Server, [[1], [name: __MODULE__]])
    ]
    Supervisor.start_link(children,
      strategy: :one_for_one,
      max_restarts: 20,
      max_seconds: 5)
  end

end
