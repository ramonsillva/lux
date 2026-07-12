defmodule LuxApp.TxManager.Replacer do
  @moduledoc """
  Transaction replacement mechanism (Speed up / Cancel) using Replace-by-Fee (RBF).
  EVM nodes require at least a 10% bump in both maxFeePerGas and maxPriorityFeePerGas.
  """

  def speed_up(tx) do
    %{
      tx |
      max_fee_per_gas: bump_10_percent(tx.max_fee_per_gas),
      max_priority_fee_per_gas: bump_10_percent(tx.max_priority_fee_per_gas)
    }
  end

  def cancel(tx) do
    %{
      to: tx.from,
      from: tx.from,
      value: 0,
      data: "0x",
      nonce: tx.nonce,
      max_fee_per_gas: bump_10_percent(tx.max_fee_per_gas),
      max_priority_fee_per_gas: bump_10_percent(tx.max_priority_fee_per_gas)
    }
  end

  defp bump_10_percent(fee) do
    Float.round(fee * 1.10, 2)
  end
end
