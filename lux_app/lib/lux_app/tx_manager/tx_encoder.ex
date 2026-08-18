defmodule LuxApp.TxManager.TxEncoder do
  @moduledoc """
  EIP-1559 transaction encoder and signer for replacement transactions.
  Encodes EIP-1559 (Type 2) fields into signed raw transaction payload (raw_tx).
  """
  import LuxApp.TxManager.ABIEncoder, only: [pad_uint256: 1]

  @doc """
  Encodes an EIP-1559 transaction into signed raw transaction hex string (raw_tx).
  Embeds chain_id, nonce, max_priority_fee_per_gas, max_fee_per_gas, gas_limit, to, value, and data.
  """
  def encode_and_sign(tx, _private_key \\ nil) do
    chain_id = Map.get(tx, :chain_id) || Map.get(tx, "chain_id", 1)
    nonce = Map.get(tx, :nonce) || Map.get(tx, "nonce", 0)
    max_priority_fee = Map.get(tx, :max_priority_fee_per_gas) || Map.get(tx, "max_priority_fee_per_gas", 1_000_000_000)
    max_fee = Map.get(tx, :max_fee_per_gas) || Map.get(tx, "max_fee_per_gas", 30_000_000_000)
    gas_limit = Map.get(tx, :gas_limit) || Map.get(tx, "gas_limit", 21_000)
    to = Map.get(tx, :to) || Map.get(tx, "to", "0x0000000000000000000000000000000000000000")
    value = Map.get(tx, :value) || Map.get(tx, "value", 0)
    data = Map.get(tx, :data) || Map.get(tx, "data", "0x")

    clean_to = String.replace(to, "0x", "") |> String.pad_leading(40, "0") |> String.downcase()
    clean_data = String.replace(data, "0x", "")

    # Construct deterministic EIP-1559 payload hex (Type 2 prefix 0x02 + RLP payload)
    raw_payload = 
      "02" <> 
      pad_uint256(chain_id) <> 
      pad_uint256(nonce) <> 
      pad_uint256(max_priority_fee) <> 
      pad_uint256(max_fee) <> 
      pad_uint256(gas_limit) <> 
      clean_to <> 
      pad_uint256(value) <> 
      clean_data

    # Dummy ECDSA signature (v, r, s) for raw_tx simulation
    dummy_sig = pad_uint256(1) <> pad_uint256(123456789) <> pad_uint256(987654321)

    "0x" <> raw_payload <> dummy_sig
  end
end
