defmodule MySuperAppWeb.OperatorsPage do
  @moduledoc false
  use MySuperAppWeb, :admin_surface_live_view
  alias MySuperApp.{CasinosAdmins, Operator}

  alias Moon.Design.{Table, Button, Modal, Form}
  alias Moon.Design.Table.Column
  alias Moon.Design.Form.{Input, Field}

  alias Moon.Design.Pagination
  alias Moon.Icons.ControlsChevronRightSmall
  alias Moon.Icons.ControlsChevronLeftSmall

  def mount(_, _, socket) do
    socket = assign(socket, current_page: 1, limit: 8, sort: [id: "ASC"])
    total_pages_task = Task.async(fn -> total_pages(socket.assigns) end)
    get_models_task = Task.async(fn -> get_models_10(socket.assigns) end)
    operators = Task.async(fn -> CasinosAdmins.get_operators() end)

    {
      :ok,
      assign(socket,
        operators: Task.await(operators),
        form: to_form(Operator.changeset(%Operator{}, %{})),
        editing?: false,
        total_pages: Task.await(total_pages_task),
        current: Task.await(get_models_task)
      )
    }
  end

  def handle_event("set_open", _params, socket) do
    Modal.open("default_modal")
    {:noreply, assign(socket, editing?: true)}
  end

  def handle_event("set_close", _, socket) do
    Process.send_after(self(), :after_close, 100)
    Modal.close("default_modal")
    {:noreply, socket}
  end

  def handle_event("validate", %{"operator" => params}, socket) do
    form =
      %Operator{}
      |> Operator.changeset(params)
      |> Map.put(:action, :insert)
      |> to_form()

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("add", %{"operator" => params}, socket) do
    Modal.close("default_modal")

    case CasinosAdmins.add_operator(params) do
      {:ok, _user} ->
        {:noreply,
         assign(socket |> put_flash(:info, "Operator added successfuly"),
           editing?: false,
           current: Task.await(Task.async(fn -> get_models_10(socket.assigns) end)),
           total_pages: total_pages(socket.assigns),
           operators: CasinosAdmins.get_operators(),
           form: to_form(Operator.changeset(%Operator{}, %{}))
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         assign(socket |> put_flash(:error, "Invalid parameters"),
           form: to_form(changeset),
           editing?: false
         )}
    end
  end

  def handle_event("set_current_page", %{"value" => page}, socket) do
    socket = assign(socket, current_page: String.to_integer(page))
    {:noreply, assign(socket, current: get_models_10(socket.assigns))}
  end

  defp get_models_10(assigns) do
    offset = (assigns.current_page - 1) * assigns.limit

    CasinosAdmins.get_operators(
      offset,
      assigns.limit
    )
  end

  defp total_pages(assigns) do
    page_count(max(length(CasinosAdmins.get_operators()), 1), assigns.limit)
  end

  defp page_count(total_count, limit) do
    ceil(total_count / limit)
  end

  def handle_info(:after_close, socket) do
    {:noreply, assign(socket, editing?: false)}
  end
end
