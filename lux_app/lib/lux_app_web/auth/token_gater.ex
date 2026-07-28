defmodule LuxAppWeb.Auth.TokenGater.Adapter do
  @moduledoc """
  Behaviour for Token Gating on-chain checks.
  """
  @callback has_access?(address :: String.t(), chain_id :: integer() | String.t(), token_contract :: String.t()) :: boolean()
end

defmodule LuxAppWeb.Auth.RPCTokenGater do
  @moduledoc """
  Production implementation performing on-chain ERC-20 / ERC-721 balance checks via JSON-RPC.
  Default closed on any network error or zero balance.
  """
  @behaviour LuxAppWeb.Auth.TokenGater.Adapter

  @impl true
  def has_access?(address, chain_id, token_contract) do
    try do
      case query_on_chain_balance(address, chain_id, token_contract) do
        {:ok, balance} when balance > 0 -> true
        _ -> false
      end
    rescue
      _ -> false
    end
  end

  defp query_on_chain_balance(address, _chain_id, token_contract) do
    clean_addr = String.replace(address, "0x", "") |> String.pad_leading(64, "0")
    # balanceOf(address) selector: 0x70a08231
    calldata = "0x70a08231" <> clean_addr

    rpc_url = Application.get_env(:lux_app, :ethereum_rpc_url, "http://127.0.0.1:8545")
    payload = Jason.encode!(%{
      "jsonrpc" => "2.0",
      "method" => "eth_call",
      "params" => [%{"to" => token_contract, "data" => calldata}, "latest"],
      "id" => 1
    })

    req = Finch.build(:post, rpc_url, [{"content-type", "application/json"}], payload)

    case Finch.request(req, LuxApp.Finch) do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"result" => result}} when is_binary(result) and result != "0x" ->
            {balance, _} = Integer.parse(String.replace(result, "0x", ""), 16)
            {:ok, balance}

          _ ->
            {:error, :invalid_rpc_response}
        end

      _ ->
        {:error, :rpc_network_error}
    end
  end
end

defmodule LuxAppWeb.Auth.TokenGater do
  @moduledoc """
  Module to verify if an address holds specific tokens (Token Gating).
  Default closed implementation using an injectable adapter.
  """

  def adapter do
    Application.get_env(:lux_app, :token_gater_adapter, LuxAppWeb.Auth.RPCTokenGater)
  end

  def has_access?(address, chain_id \\ 1, token_contract \\ "0x0000000000000000000000000000000000000000") do
    adapter().has_access?(address, chain_id, token_contract)
  end
end
