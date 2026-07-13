defmodule LuxApp.TxManager.Simulator do
  @moduledoc """
  Transaction simulation system.
  """

  @rpc_adapter Application.compile_env(:lux_app, :rpc_adapter, LuxApp.TxManager.MockRPC)

  @doc """
  Simulates a transaction execution using the RPC Adapter to estimate required gas.
  """
  def estimate(tx) do
    case @rpc_adapter.estimate_gas(tx) do
      {:ok, gas_limit} -> {:ok, gas_limit}
      {:error, reason} -> {:error, reason}
    end
  end
end

defmodule LuxApp.TxManager.Reporter do
  @moduledoc """
  Cost analysis reporting.
  """

  def calculate_savings([], _batched_tx) do
    %{
      original_gas_cost: 0,
      batched_gas_cost: 0,
      gas_saved: 0,
      saved_percentage: 0.0
    }
  end

  def calculate_savings(original_txs, batched_tx) do
    original_gas = length(original_txs) * 21_000
    batched_gas = 21_000 # Just base cost, ignoring internal call diffs for pure metric
    
    gas_saved = original_gas - batched_gas
    
    %{
      original_gas_cost: original_gas,
      batched_gas_cost: batched_gas,
      gas_saved: gas_saved,
      saved_percentage: Float.round((gas_saved / original_gas) * 100, 2)
    }
  end
end
