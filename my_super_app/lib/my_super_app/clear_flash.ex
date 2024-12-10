defmodule MySuperApp.ClearFlash do
  @moduledoc """
    clears flash inside, used inside hook in app.js
  """
  use Phoenix.LiveView

  def handle_event("lv:clear-flash", %{"key" => key}, socket) do
    {:noreply, clear_flash(socket, String.to_existing_atom(key))}
  end
end
