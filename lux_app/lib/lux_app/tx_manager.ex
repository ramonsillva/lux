defmodule LuxApp.TxManager do
  @moduledoc """
  Context facade for Gas Optimization and Transaction Management.
  """
  
  alias LuxApp.TxManager.{GasOracle, Batcher, Optimizer, Replacer, MevProtector, Simulator, Reporter}

  def delegate_estimate_gas(tx), do: Simulator.estimate(tx)
  
  def optimize_gas_fees(strategy \\ :standard) do
    base_fee = GasOracle.get_current_base_fee()
    Optimizer.calculate_eip1559_fees(base_fee, strategy)
  end

  def protect_transaction(tx, options \\ []) do
    MevProtector.wrap_for_private_mempool(tx, options)
  end

  def speed_up(tx), do: Replacer.speed_up(tx)
  def cancel(tx), do: Replacer.cancel(tx)

  def batch_transactions(txs), do: Batcher.create_multicall(txs)
  
  def report_savings(original_txs, batched_tx), do: Reporter.calculate_savings(original_txs, batched_tx)
end
