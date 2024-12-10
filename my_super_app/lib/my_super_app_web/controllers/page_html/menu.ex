defmodule MySuperAppWeb.Menu do
  @moduledoc """
    simple menu without href
  """
  use MySuperAppWeb, :surface_live_view
  alias Moon.Design.MenuItem
  alias Moon.Lego
  alias MySuperApp.{Repo, LeftMenu}

  data(expanded0, :boolean, default: false)
  data(expanded1, :boolean, default: true)
  data(expanded2, :boolean, default: false)
  data(left_menu, :any, default: [])

  def mount(_params, _session, socket) do
    {:ok, assign(socket, left_menu: LeftMenu |> Repo.all())}
  end

  def handle_event("on_expand" <> number, params, socket) do
    {:noreply, assign(socket, :"expanded#{number}", params["is-selected"] |> convert!)}
  end

  defp convert!("true"), do: true
  defp convert!("false"), do: false
end
