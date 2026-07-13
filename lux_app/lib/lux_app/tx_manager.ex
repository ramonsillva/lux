defmodule LuxApp.TxManager do
  @moduledoc """
  Context facade for Gas Optimization and Transaction Management.
  
  ## Architecture
  This module orchestrates EVM transactions to guarantee cost efficiency and protection.
  
  ## Examples
  
      # 1. Optimize gas fees using EIP-1559 strategy
      fees = LuxApp.TxManager.optimize_gas_fees(:fast)
      
      # 2. Batch multiple transactions to save base gas (21k per tx)
      batch = LuxApp.TxManager.batch_transactions([%{to: "0x1"}, %{to: "0x2"}])
      
      # 3. Protect against MEV using Flashbots
      protected_tx = LuxApp.TxManager.protect_transaction(batch, builder: "flashbots")
      
      # 4. Speed up a stuck transaction
      faster_tx = LuxApp.TxManager.speed_up(stuck_tx)
  """
  
  alias LuxApp.TxManager.{GasOracle, Batcher, Optimizer, Replacer, MevProtector, Simulator, Reporter, GasToken}

  @rpc_adapter Application.compile_env(:lux_app, :rpc_adapter, LuxApp.TxManager.MockRPC)

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
  
  def apply_gas_token(tx, token_address, amount), do: GasToken.wrap_with_gas_token(tx, token_address, amount)
  
  def wait_for_receipt(hash), do: @rpc_adapter.get_transaction_receipt(hash)
end
