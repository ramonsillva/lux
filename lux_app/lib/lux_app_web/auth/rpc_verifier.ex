defmodule LuxAppWeb.Auth.RPCVerifier do
  @moduledoc """
  Production implementation of ERC-1271 verifier calling `isValidSignature(bytes32, bytes)` via JSON-RPC.
  Magic value expected: 0x1626ba7e
  Default Closed: returns false on network, decode, timeout, or revert errors.
  """
  @behaviour LuxAppWeb.Auth.EIP1271Verifier

  # Magic value 0x1626ba7e defined by ERC-1271 (bytes4)
  @magic_value "1626ba7e"

  @impl true
  def is_valid_signature?(message, signature, contract_address) do
    try do
      # 1. Compute EIP-191 message hash: \x19Ethereum Signed Message:\n<length><message>
      eth_message = "\x19Ethereum Signed Message:\n#{byte_size(message)}#{message}"
      hash = ExKeccak.hash_256(eth_message)
      hash_hex = Base.encode16(hash, case: :lower)

      # 2. Format isValidSignature(bytes32,bytes) payload: selector 0x1626ba7e
      clean_sig = String.replace(signature, "0x", "")
      calldata = "0x1626ba7e" <> hash_hex <> pad_bytes(clean_sig)

      rpc_url = Application.get_env(:lux_app, :ethereum_rpc_url, "http://127.0.0.1:8545")

      case perform_json_rpc(rpc_url, contract_address, calldata) do
        {:ok, return_data} ->
          clean_return = String.replace(return_data, "0x", "")
          String.starts_with?(clean_return, @magic_value)

        _error ->
          # Default closed on any network/RPC error
          false
      end
    rescue
      _ -> false
    end
  end

  defp perform_json_rpc(rpc_url, contract_address, calldata) do
    payload = Jason.encode!(%{
      "jsonrpc" => "2.0",
      "method" => "eth_call",
      "params" => [%{"to" => contract_address, "data" => calldata}, "latest"],
      "id" => 1
    })

    req = Finch.build(:post, rpc_url, [{"content-type", "application/json"}], payload)

    case Finch.request(req, LuxApp.Finch) do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"result" => result}} when is_binary(result) -> {:ok, result}
          _ -> {:error, :invalid_rpc_response}
        end

      _ ->
        {:error, :rpc_network_error}
    end
  end

  defp pad_bytes(hex) do
    len = trunc(byte_size(hex) / 2)
    len_hex = Integer.to_string(len, 16) |> String.pad_leading(64, "0")
    padded_hex = String.pad_trailing(hex, trunc(Float.ceil(byte_size(hex) / 64) * 64), "0")
    "0000000000000000000000000000000000000000000000000000000000000040" <> len_hex <> padded_hex
  end
end
