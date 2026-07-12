defmodule LuxAppWeb.ProfileController do
  use LuxAppWeb, :controller

  def show(conn, _params) do
    # This route is protected by RequireAuth
    address = get_session(conn, :web3_address)
    role = get_session(conn, :role)

    gater = Application.get_env(:lux_app, :token_gater, LuxAppWeb.Auth.TokenGater)
    has_premium_pass = gater.has_access?(address)

    if has_premium_pass do
      conn
      |> put_status(:ok)
      |> json(%{
        address: address,
        role: role,
        premium_access: true,
        message: "Successfully authenticated via Web3 SIWE."
      })
    else
      conn
      |> put_status(:forbidden)
      |> json(%{error: "Insufficient token balance for premium access."})
    end
  end
end
