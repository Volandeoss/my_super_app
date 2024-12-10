defmodule MySuperAppWeb.Tabs do
  @moduledoc """
    tabs
  """
  use MySuperAppWeb, :surface_live_view
  alias MySuperApp.DbQueries
  alias Moon.Design.Tabs
  alias Moon.Design.Accordion
  alias Moon.Design.Table
  alias Moon.Design.Table.Column
  alias MySuperApp.{DbQueries}
  import MoonWeb.Helpers.Lorem

  prop(selected, :list, default: [])

  data(rooms_with_phones, :any, default: [])
  data(rooms_without_phones, :any, default: [])
  data(phones_no_rooms, :any, default: [])

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       rooms_with_phones: DbQueries.rooms_with_phones(),
       rooms_without_phones: DbQueries.rooms_without_phones(),
       phones_no_rooms: DbQueries.phones_without_rooms(),
       selected: []
     )}
  end
end
