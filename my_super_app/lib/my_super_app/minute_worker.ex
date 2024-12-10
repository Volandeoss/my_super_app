defmodule MySuperApp.MinuteWorker do
  @moduledoc """
    minute worker for test
  """
  use Oban.Worker, queue: :default, max_attempts: 3
  alias MySuperApp.SendBySwoosh

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"current_user" => current_user, "post" => post}}) do
    SendBySwoosh.send_email(current_user, post)
    :ok
  end

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    IO.puts("minute passed")
    :ok
  end
end
