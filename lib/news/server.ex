defmodule News.Server do
  use GenServer

  @update_time [hours: 23, minutes: 50, seconds: 0]
  use Timex

  def start_link(state, opts \\ []) do
    GenServer.start_link(__MODULE__, state, opts)
  end

  def init(_) do
    timeout = remain_ms(@update_time)
    {:ok, {Timex.DateTime.local, :ok, timeout}, timeout}
  end

  def handle_info(:timeout, _state) do
    new_state =
      try  do
        News.Github.News.update
        New.Github.Awesome.update
        {Timex.DateTime.local, :ok, remain_ms(@update_time)}
      catch error ->
          {Timex.DateTime.local, error, remain_ms(@update_time)}
      end
    {:noreply, new_state, remain_ms(@update_time)}
  end

  def remain_ms(time) do
    update_datetime =
      "Asia/Shanghai"
      |> Timex.DateTime.today
      |> Timex.shift(time)
    now = Timex.DateTime.now
    diff_ms = Timex.diff(update_datetime, now, :seconds) * 1000
    if Timex.after?(now, update_datetime), do: 86400000 - diff_ms, else: diff_ms
  end

end

