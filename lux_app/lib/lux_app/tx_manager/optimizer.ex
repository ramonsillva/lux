defmodule LuxApp.TxManager.Optimizer do
  @moduledoc """
  Priority fee optimization and EIP-1559 strategies.
  """

  @doc """
  Calculates maxFeePerGas and maxPriorityFeePerGas based on the current base fee and strategy.
  Strategies: :economy, :standard, :fast
  """
  def calculate_eip1559_fees(base_fee, strategy) do
    priority_fee = get_priority_fee(strategy)
    
    # maxFeePerGas = (base_fee * 2) + priority_fee (Standard EIP-1559 formula to handle base_fee spikes)
    max_fee = (base_fee * 2) + priority_fee

    %{
      max_fee_per_gas: Float.round(max_fee, 2),
      max_priority_fee_per_gas: Float.round(priority_fee, 2)
    }
  end

  defp get_priority_fee(:economy), do: 1.0
  defp get_priority_fee(:standard), do: 2.0
  defp get_priority_fee(:fast), do: 5.0
end
