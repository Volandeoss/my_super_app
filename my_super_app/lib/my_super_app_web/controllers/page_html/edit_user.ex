defmodule MySuperAppWeb.EditUser do
  @moduledoc """
  form to edit user
  """
  use MySuperAppWeb, :surface_live_view
  alias MySuperApp.Accounts
  alias Moon.Design.Form
  alias Moon.Design.Form.Input
  alias Moon.Design.Form.InsetField
  alias MoonWeb.Schema.User
  alias Moon.Design.Button

  prop(user_changeset, :any, default: User.changeset(%User{}))

  def mount(%{"id" => id}, _session, socket) do
    user = Accounts.get_user_by_id(id)
    {:ok, assign(socket, form: to_form(User.changeset(%User{}, %{})), main_user: user)}
  end

  def render(assigns) do
    ~F"""
    <h1>Old username: {@main_user.username}</h1>
    <h1>Old email: {@main_user.email}</h1>

    <Form for={@form} submit="save">
      <InsetField label="insert new username">
        <Input />
      </InsetField>

      <InsetField label="insert new email">
        <Input />
      </InsetField>

      <Input type="hidden" value={@main_user.id} />

      <Button type="submit" animation="success">Success</Button>
    </Form>
    """
  end

  def handle_event("changed", %{"user" => params}, socket) do
    {:noreply, assign(socket, user_changeset: User.changeset(%User{}, params))}
  end

  def handle_event("validate", %{"user" => params}, socket) do
    form =
      %User{}
      |> User.changeset(params)
      |> Map.put(:action, :insert)
      |> to_form()

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("save", %{"user" => [username, email, id]}, socket) do
    params = %{username: username, email: email, id: id}

    case Accounts.update_user(id, params) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "user updated")
         |> redirect(to: ~p"/menu")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  def handle_event("single_row_click", %{"selected" => selected}, socket) do
    {:noreply, assign(socket, selected: [selected])}
  end
end
