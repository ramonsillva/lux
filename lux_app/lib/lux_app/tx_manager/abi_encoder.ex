defmodule LuxApp.TxManager.ABIEncoder do
  @moduledoc """
  Solidity ABI encoder complying with EIP-2718 / Solidity ABI Specification.
  Encodes Multicall3 `aggregate3((address target, bool allowFailure, bytes callData)[])`.
  """

  # Selector for aggregate3((address,bool,bytes)[]) = 0x82ad56cb
  @aggregate3_selector "82ad56cb"

  @doc """
  Encodes a list of calls into a canonical Multicall3 aggregate3 ABI binary hex payload.
  """
  def encode_multicall(calls) when is_list(calls) do
    count = length(calls)
    array_offset = pad_uint256(32)
    array_len = pad_uint256(count)

    # Encode tuple heads and tails
    {heads, tails} = encode_tuples(calls, count * 32, [], [])

    "0x" <> @aggregate3_selector <> array_offset <> array_len <> Enum.join(heads, "") <> Enum.join(tails, "")
  end

  defp encode_tuples([], _current_offset, heads_acc, tails_acc) do
    {Enum.reverse(heads_acc), Enum.reverse(tails_acc)}
  end

  defp encode_tuples([call | rest], current_offset, heads_acc, tails_acc) do
    target = Map.get(call, :to) || Map.get(call, "to", "0x0000000000000000000000000000000000000000")
    allow_failure = Map.get(call, :allow_failure, true)
    raw_data = Map.get(call, :data) || Map.get(call, "data", "0x")

    clean_target = String.replace(target, "0x", "") |> String.pad_leading(64, "0")
    bool_val = if allow_failure, do: pad_uint256(1), else: pad_uint256(0)

    clean_data = String.replace(raw_data, "0x", "")
    data_byte_size = trunc(byte_size(clean_data) / 2)
    data_len_hex = pad_uint256(data_byte_size)
    padded_data_hex = pad_bytes_right(clean_data)

    # Calldata offset inside the tuple is 0x60 (96 bytes: target + allowFailure + offset)
    calldata_offset_in_tuple = pad_uint256(96)
    tuple_encoded = clean_target <> bool_val <> calldata_offset_in_tuple <> data_len_hex <> padded_data_hex

    head = pad_uint256(current_offset)
    next_offset = current_offset + trunc(byte_size(tuple_encoded) / 2)

    encode_tuples(rest, next_offset, [head | heads_acc], [tuple_encoded | tails_acc])
  end

  def pad_uint256(val) when is_integer(val) do
    Integer.to_string(val, 16) |> String.pad_leading(64, "0") |> String.downcase()
  end

  def pad_bytes_right(hex) when is_binary(hex) do
    clean = String.replace(hex, "0x", "")
    if clean == "" do
      ""
    else
      target_len = trunc(Float.ceil(byte_size(clean) / 64) * 64)
      target_len = if target_len == 0, do: 64, else: target_len
      String.pad_trailing(clean, target_len, "0") |> String.downcase()
    end
  end
end
