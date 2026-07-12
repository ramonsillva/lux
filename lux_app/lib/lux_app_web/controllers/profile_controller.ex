defmodule LuxAppWeb.ProfileController do
  use LuxAppWeb, :controller

  def show(conn, _params) do
    # This route is protected by RequireAuth
    address = get_session(conn, :web3_address)
    role = get_session(conn, :role)

    # Simulated Token Gating check
    # In a real app we'd query an RPC node to check token balance
    has_premium_pass = check_token_gating(address)

    conn
    |> put_status(:ok)
    |> json(%{
      address: address,
      role: role,
      premium_access: has_premium_pass,
      message: "Successfully authenticated via Web3 SIWE."
    })
  end

  defp check_token_gating(_address) do
    # Simulated token balance check
    true
  end
end
