defmodule MySuperAppWeb.SitePage do
  @moduledoc false
  alias Moon.Components.Table.Column
  use MySuperAppWeb, :admin_surface_live_view

  alias Moon.Design.Search

  alias MySuperApp.{CasinosAdmins, CasinoSites}

  alias Moon.Design.{
    Table,
    Chip,
    Form,
    Modal,
    Form.Field,
    Form.Input,
    Dropdown,
    Button.IconButton,
    Button
  }

  alias Moon.Design.Tooltip

  alias Moon.Design.Table.Column

  alias Moon.Design.Pagination
  alias Moon.Icons.ControlsChevronRight
  alias Moon.Icons.ControlsChevronLeft

  data(site, :any, default: %{brand: "", operator_id: "", status: false, operator_name: ""})
  data(time_open?, :boolean, default: false)

  def mount(_, _, socket) do
    if connected?(socket) do
      CasinoSites.subscribe()
    end

    socket =
      assign(socket,
        from: "",
        to: "",
        filter: "",
        sort: [id: "ASC"],
        current_page: 1,
        limit: 8
      )

    {
      :ok,
      assign(socket,
        sites: CasinoSites.get_sites_with_operators(),
        form: to_form(CasinoSites.clear_form()),
        editing?: false,
        operators: CasinosAdmins.get_operators(),
        value: nil,
        site_id: nil,
        type: "datetime-local",
        time_form: to_form(CasinoSites.clear_time_form()),
        current: get_models_10(socket.assigns)
      )
    }
  end

  def handle_event("open_time", _, socket) do
    {:noreply, assign(socket, time_open?: !socket.assigns.time_open?)}
  end

  def handle_event("change_status", %{"value" => site_id}, socket) do
    CasinoSites.update_site_status(site_id)
    get_models_10(socket.assigns)
    {:noreply, assign(socket, current: get_models_10(socket.assigns))}
  end

  def handle_event(
        "handle_sorting_click",
        %{"sort-dir" => sort_dir, "sort-key" => sort_key},
        socket
      ) do
    socket = assign(socket, sort: ["#{sort_key}": sort_dir])
    {:noreply, socket |> assign(current: get_models_10(socket.assigns))}
  end

  def handle_event("clear_all", _params, socket) do
    socket =
      assign(socket,
        sort: [id: "ASC"],
        filter: "",
        from: "",
        to: "",
        time_open?: false,
        time_form: to_form(CasinoSites.clear_time_form())
      )

    {:noreply,
     assign(socket,
       current: get_models_10(socket.assigns)
     )}
  end

  def handle_event(
        "change_time",
        %{
          "site" => %{
            "inserted_at" => from,
            "updated_at" => ""
          }
        },
        socket
      ) do
    form =
      CasinoSites.change_time(%{inserted_at: from, updated_at: socket.assigns.to})
      |> to_form()

    socket = assign(socket, from: from, current_page: 1)

    {:noreply, assign(socket, current: get_models_10(socket.assigns), time_form: form)}
  end

  def handle_event(
        "change_time",
        %{
          "site" => %{
            "inserted_at" => "",
            "updated_at" => to
          }
        },
        socket
      ) do
    form =
      CasinoSites.change_time(%{inserted_at: socket.assigns.from, updated_at: to})
      |> to_form()

    socket = assign(socket, to: to, current_page: 1)
    {:noreply, assign(socket, current: get_models_10(socket.assigns), time_form: form)}
  end

  def handle_event(
        "change_time",
        %{
          "site" => %{
            "inserted_at" => from,
            "updated_at" => to
          }
        },
        socket
      ) do
    form =
      CasinoSites.change_time(%{inserted_at: from, updated_at: to})
      |> to_form()

    socket = assign(socket, from: from, to: to, current_page: 1)

    {:noreply, assign(socket, current: get_models_10(socket.assigns), time_form: form)}
  end

  def handle_event("handle_paging_click", %{"value" => value}, socket) do
    socket = assign(socket, current_page: String.to_integer(value))
    {:noreply, assign(socket, current: get_models_10(socket.assigns))}
  end

  def handle_event("change_filter", %{"value" => filter}, socket) do
    socket = assign(socket, filter: filter, current_page: 1)
    {:noreply, assign(socket, current: get_models_10(socket.assigns))}
  end

  def handle_event(
        "on_sorting_click",
        %{"sort-dir" => sort_dir, "sort-key" => sort_key},
        socket
      ) do
    socket = assign(socket, sort: ["#{sort_key}": sort_dir])

    {:noreply,
     assign(socket,
       current: get_models_10(socket.assigns),
       updated?: false
     )}
  end

  def handle_event("delete", _params, socket) do
    CasinoSites.delete_site(socket.assigns.site.id)

    Modal.close("default_modal")

    total_pages = total_pages(socket.assigns)

    socket =
      assign(socket,
        total_pages: total_pages,
        current_page:
          if(total_pages < socket.assigns.current_page,
            do: total_pages,
            else: socket.assigns.current_page
          )
      )

    {:noreply,
     assign(socket |> put_flash(:info, "site deleted"),
       sites: CasinoSites.get_sites_with_operators(),
       current: get_models_10(socket.assigns)
     )}
  end

  def handle_event("set_open", %{"value" => ""}, socket) do
    Modal.open("default_modal")
    {:noreply, assign(socket, editing?: true)}
  end

  def handle_event("set_open", %{"value" => value}, socket) do
    site =
      socket.assigns.sites
      |> Enum.find(fn site -> site.id == String.to_integer(value) end)

    Modal.open("default_modal")
    {:noreply, assign(socket, editing?: true, site_id: value, site: site)}
  end

  def handle_event("set_close", _, socket) do
    Modal.close("default_modal")
    Process.send_after(self(), :after_close, 200)

    {:noreply,
     assign(socket,
       form: to_form(CasinoSites.clear_form()),
       site: %{brand: "", operator_id: "", status: false, operator_name: ""}
     )}
  end

  def handle_event("validate", %{"site" => params}, socket) do
    attrs =
      params
      |> Map.put("operator_id", socket.assigns.current_user.operator_id)

    form =
      CasinoSites.change_form(attrs)
      |> to_form()

    {:noreply, assign(socket, form: form, site: attrs)}
  end

  def handle_event("add", %{"site" => params}, socket) do
    attrs = params |> Map.put("operator_id", socket.assigns.current_user.operator_id)
    Modal.close("default_modal")

    case CasinoSites.create_site(attrs) do
      {:ok, _site} ->
        {:noreply,
         assign(socket |> put_flash(:info, "New site created"),
           editing?: false,
           form: to_form(CasinoSites.clear_form()),
           current: get_models_10(socket.assigns),
           total_pages: total_pages(socket.assigns),
           site_id: nil
         )}

      {:error, _} ->
        {:noreply,
         assign(socket |> put_flash(:warn, "Not unique"),
           editing?: false,
           form: to_form(CasinoSites.clear_form()),
           site_id: nil
         )}
    end
  end

  def get_models_10(assigns) do
    offset = (assigns.current_page - 1) * assigns.limit

    CasinoSites.get_sites_with_operators(
      offset,
      assigns.limit,
      assigns.sort,
      assigns.filter,
      assigns.from,
      assigns.to
    )
  end

  defp total_pages(assigns) do
    page_count(
      max(
        length(
          CasinoSites.get_sites_with_operators(
            assigns.sort,
            assigns.filter,
            assigns.from,
            assigns.to
          )
        ),
        1
      ),
      assigns.limit
    )
  end

  def handle_info(:after_close, socket) do
    {:noreply, assign(socket, site_id: nil, editing?: false)}
  end

  def handle_info({:site_created, site}, socket) do
    {:noreply,
     assign(socket |> put_flash(:info, "site #{site.id} created"),
       total_pages: total_pages(socket.assigns),
       current: get_models_10(socket.assigns)
     )}
  end

  defp page_count(total_count, limit) do
    ceil(total_count / limit)
  end
end
