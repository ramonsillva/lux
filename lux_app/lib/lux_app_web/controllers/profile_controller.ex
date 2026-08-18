defmodule LuxAppWeb.ProfileController do
  use LuxAppWeb, :controller

  def show(conn, _params) do
    address = get_session(conn, :web3_address)
    role = get_session(conn, :role)
    session_chain_id = get_session(conn, :chain_id) || "1"

    policy = Application.get_env(:lux_app, :token_gating_policy, %{
      chain_id: 1,
      token_contract: "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48", # Default configured token
      min_balance: 1
    })

    target_chain = policy[:chain_id] || session_chain_id
    target_contract = policy[:token_contract]
    min_balance = policy[:min_balance] || 1

    gater = Application.get_env(:lux_app, :token_gater, LuxAppWeb.Auth.TokenGater)
    has_premium_pass = gater.has_access?(address, target_chain, target_contract, min_balance)

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
