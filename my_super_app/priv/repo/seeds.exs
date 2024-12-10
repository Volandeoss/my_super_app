# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     MySuperApp.Repo.insert!(%MySuperApp.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

# MySuperApp.Repo.insert_all(
#   "left_menu",
#   [
#     %{id: 1, title: "Vision"},
#     %{id: 2, title: "Getting started"},
#     %{id: 3, title: "How to contribute?"},
#     %{id: 4, title: "Colours"},
#     %{id: 5, title: "Tokens"},
#     %{id: 6, title: "Transform SVG"},
#     %{id: 7, title: "Manifest"},
#     %{id: 8, title: "Tailwind"}
#   ]
# )
# alias MySuperApp.{Repo, Room, User, Accounts, Phone}

# rooms_with_phones = %{
#   "301" => ["0991122301", "0993344301"],
#   "302" => ["0990000302", "0991111302"],
#   "303" => ["0992222303"],
#   "304" => ["0993333304", "0994444304"],
#   "305" => ["0935555305", "09306666305", "0937777305"]
# }

# for _ <- 1..10 do
#   Accounts.create_user(%{username: Internet.user_name(), email: Internet.email()})
# end

# Repo.transaction(fn ->
#   rooms_with_phones
#   |> Enum.each(fn {room, phones} ->
#     %Room{}
#     |> Room.changeset(%{room_number: room})
#     |> Ecto.Changeset.put_assoc(
#       :phones,
#       phones
#       |> Enum.map(
#         &(%Phone{}
#           |> Phone.changeset(%{phone_number: &1}))
#       )
#     )
#     |> Repo.insert!()
#   end)

#   MySuperApp.Repo.insert_all(
#     Room,
#     [
#       %{room_number: 666},
#       %{room_number: 1408},
#       %{room_number: 237}
#     ]
#   )

#   MySuperApp.Repo.insert_all(
#     Phone,
#     [
#       %{phone_number: "380661112233"},
#       %{phone_number: "380669997788"},
#       %{phone_number: "380665554466"}
#     ]
#   )
# end)
# MySuperApp.AccountsAuth.register_user(%{
#   username: "first_user",
#   password: "12345678",
#   email: "first_user@gmail",
#   operator_id: 1
# })

# MySuperApp.AccountsAuth.register_user(%{
#   username: "second_user",
#   password: "12345678",
#   email: "second_user@gmail",
#   operator_id: 2
# })

alias Faker.Internet
import MoonWeb.Helpers.Lorem
alias MySuperApp.Blog

MySuperApp.AccountsAuth.register_user(%{
  username: "vladik",
  password: "12345678",
  email: "ossasvladislav@gmail.com",
  superadmin: true
})

for x <- 1..5 do
  MySuperApp.CasinosAdmins.add_operator(%{name: Faker.Company.name()})
  MySuperApp.CasinosRoles.add_role(%{name: Faker.Pokemon.En.name(), operator_id: x})
  MySuperApp.CasinosRoles.add_role(%{name: Faker.Pokemon.En.name(), operator_id: x})
  MySuperApp.CasinosRoles.add_role(%{name: Faker.Pokemon.En.name(), operator_id: x})
end

for _x <- 1..30 do
  Blog.create_until_success(
    MySuperApp.CasinoSites.create_site(%{
      brand: Faker.Company.En.bullshit(),
      status: false,
      operator_id: :rand.uniform(4)
    })
  )
end

for x <- 1..30 do
  name = Internet.user_name()

  cond do
    x <= 5 ->
      MySuperApp.AccountsAuth.register_user(%{
        username: name,
        password: "12345678",
        email: "#{name}@gmail",
        operator_id: x
      })

    x > 5 && x < 20 ->
      MySuperApp.AccountsAuth.register_user(%{
        username: name,
        password: "12345678",
        email: "#{name}@gmail",
        role_id: :rand.uniform(15)
      })

    true ->
      MySuperApp.AccountsAuth.register_user(%{
        username: name,
        password: "12345678",
        email: "#{name}@gmail"
      })
  end
end

for _x <- 1..20 do
  MySuperApp.Blog.create_post_and_associate_tags(
    %{title: Faker.Internet.slug(), body: lorem(), user_id: :rand.uniform(10)},
    [
      %{title: Faker.Food.En.dish()},
      %{title: Faker.Food.En.dish()},
      %{title: Faker.Food.En.dish()}
    ]
  )
end
