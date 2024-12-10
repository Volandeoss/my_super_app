defmodule MySuperApp.SendBySwoosh do
  @moduledoc """
   module to form email structures
  """
  import Swoosh.Email
  alias MySuperApp.Mailer

  def send_email(current_user, post) do
    new()
    |> from({"Vl", "ossasvladislav@gmail.com"})
    |> to({current_user["username"], current_user["email"]})
    |> subject("The post has been created")
    |> html_body("""
      <h1>The post has been created</h1>
          <div class="flex justify-center">
          <p><b>Title: #{post["title"]}</b></p>
          </div>
          <p>Body:#{post["body"]}</p>
    """)
    |> Mailer.deliver()
  end
end
