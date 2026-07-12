defmodule LuxApp.TxManager.Simulator do
  @moduledoc """
  Transaction simulation system.
  """

  def estimate(%{type: :multicall, calls: calls}) do
    # Simula 21000 custo base + 30000 por cada chamada interna
    21_000 + (length(calls) * 30_000)
  end

  def estimate(_tx) do
    # Simulando uma tx padrão
    21_000
  end
end

defmodule LuxApp.TxManager.Reporter do
  @moduledoc """
  Cost analysis reporting.
  """

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
