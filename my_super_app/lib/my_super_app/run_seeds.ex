defmodule MySuperApp.RunSeeds do
  alias MySuperApp.{Accounts, CasinoSites, CasinosAdmins, CasinosRoles, Blog}
  alias Faker.Internet


  import MoonWeb.Helpers.Lorem

  @moduledoc false
  def run_posts() do
    for x <- 0..30 do
      MySuperApp.Blog.create_post_and_associate_tags(
        %{title: "Post_numba_#{x}", body: "some Body for post_#{x}", user_id: x + 1},
        [%{title: "Tag_#{x}"}, %{title: "Tag_#{x}"}, %{title: "Tag_#{x}"}]
      )
    end
  end

  def initil() do
    Accounts.delete_all()
    Blog.delete_all_posts()
    Blog.delete_all_pictures()
    CasinosRoles.delete_all_roles()
    CasinosAdmins.delete_all()
    CasinoSites.delete_all()

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

  end
end
