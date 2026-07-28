defmodule LuxAppWeb.Auth.EIP1271Verifier do
  @moduledoc """
  Behaviour for EIP-1271 contract wallet signature verification.
  """

  @doc """
  Verifies if a contract wallet signature is valid for a given SIWE message.
  Must return true only if the contract responds with magic value 0x1626ba7e.
  """
  @callback is_valid_signature?(message :: String.t(), signature :: String.t(), contract_address :: String.t()) :: boolean()
end
