defmodule News.Server do
  use GenServer

  @update_time {11, 50, 00}

  def start_link(state, opts \\ []) do
    GenServer.start_link(__MODULE__, state, opts)
  end

  def init([state]) do
    timeout = remain_ms(@update_time)
    {:ok, state, timeout}
  end

  def handle_info(:timeout, state) do
    News.Github.update_news
    timeout = remain_ms(@update_time)
    {:noreply, state + 1, timeout}
  end

  def remain_ms(time) do
    { date, _ } = :calendar.local_time
    now = Timex.DateTime.local
    update_time = Timex.datetime({date, time}, "Asia/Shanghai")
    diff_ms = Timex.diff(update_time, now, :seconds) * 1000
    case Timex.after?(now, update_time) do
      true -> 
        86400000 - diff_ms
      false ->
        diff_ms
    end
  end

end

