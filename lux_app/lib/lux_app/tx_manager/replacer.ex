defmodule LuxApp.TxManager.Replacer do
  @moduledoc """
  Transaction replacement mechanism (Speed up / Cancel) using Replace-by-Fee (RBF).
  EVM nodes require at least a 10% bump in both maxFeePerGas and maxPriorityFeePerGas.
  """

  @rpc_adapter Application.compile_env(:lux_app, :rpc_adapter, LuxApp.TxManager.MockRPC)

  @doc """
  Speeds up a transaction by bumping fees by 10% and resubmitting.
  """
  def speed_up(tx) do
    new_tx = %{
      tx |
      max_fee_per_gas: bump_10_percent(tx.max_fee_per_gas),
      max_priority_fee_per_gas: bump_10_percent(tx.max_priority_fee_per_gas)
    }
    send_replacement(new_tx)
  end

  @doc """
  Cancels a transaction by sending an empty payload to self with bumped fees.
  """
  def cancel(tx) do
    new_tx = %{
      to: tx.from,
      from: tx.from,
      value: 0,
      data: "0x",
      nonce: tx.nonce,
      max_fee_per_gas: bump_10_percent(tx.max_fee_per_gas),
      max_priority_fee_per_gas: bump_10_percent(tx.max_priority_fee_per_gas)
    }
    send_replacement(new_tx)
  end
  
  defp send_replacement(new_tx) do
    case @rpc_adapter.send_transaction(new_tx) do
      {:ok, hash} -> {:ok, hash, new_tx}
      {:error, :replacement_underpriced} -> 
        # Bump again automatically
        speed_up(new_tx)
      {:error, reason} -> {:error, reason}
    end
  end

  # Bumps the fee by exactly 10% using integer math to avoid EVM Float precision errors
  defp bump_10_percent(fee) when is_integer(fee) do
    div(fee * 110, 100)
  end
  defp bump_10_percent(fee) do
    trunc(fee * 1.10)
  end
end
