defmodule MySuperAppWeb.HomeLive do
  use MySuperAppWeb, :surface_live_view
  alias Moon.Design.Button
  alias MySuperApp.AccountsAuth

  def mount(_params, session, socket) do
    current_user =
      if session["user_token"] do
        AccountsAuth.get_user_by_session_token(session["user_token"])
      else
        nil
      end

    {:ok, assign(socket, current_user: current_user)}
  end
end
