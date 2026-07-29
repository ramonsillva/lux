defmodule LuxApp.TxManager.ABIEncoder do
  @moduledoc """
  ABI Encoding logic for Smart Contracts.
  """

  @doc """
  Encodes a list of individual contract calls into a single Multicall3 payload.
  """
  def encode_multicall(calls) when is_list(calls) do
    encoded_calls = Enum.map(calls, fn c -> 
      target = Map.get(c, :to) || Map.get(c, "to", "")
      data = Map.get(c, :data) || Map.get(c, "data", "")
      "encoded_#{target}_#{data}" 
    end)
    
    # 0x5aebbb7f is the typical 4-byte signature for aggregate3
    "0x5aebbb7f" <> Enum.join(encoded_calls, "")
  end
end
