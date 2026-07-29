defmodule LuxApp.TxManager.GasToken do
  @moduledoc """
  Integrates Gas Tokens (CHI/GST2) to reduce transaction costs by freeing storage via ABI encoding.
  """
  import LuxApp.TxManager.ABIEncoder, only: [pad_uint256: 1]

  # Selector for freeFromUpTo(address,uint256) = 0xd7db9b35
  @free_from_up_to_selector "d7db9b35"

  @doc """
  Wraps a transaction payload to include an ABI-encoded call to free up to `amount` of gas tokens.
  """
  def wrap_with_gas_token(tx, token_address, amount) when is_integer(amount) do
    encoded_free_call = encode_free_from_up_to(token_address, amount)
    current_data = Map.get(tx, :data) || Map.get(tx, "data", "0x")
    
    clean_data = String.replace(current_data, "0x", "")
    %{tx | data: "0x" <> clean_data <> encoded_free_call}
  end

  @doc """
  Encodes freeFromUpTo(address,uint256) according to Solidity ABI specifications.
  """
  def encode_free_from_up_to(token_address, amount) do
    clean_addr = String.replace(token_address, "0x", "") |> String.pad_leading(64, "0") |> String.downcase()
    amount_hex = pad_uint256(amount)

    @free_from_up_to_selector <> clean_addr <> amount_hex
  end
end
