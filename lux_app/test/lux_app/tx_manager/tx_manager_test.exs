defmodule LuxApp.TxManagerTest do
  use ExUnit.Case

  alias LuxApp.TxManager
  alias LuxApp.TxManager.GasOracle

  setup do
    # Ensure GasOracle is started for tests
    case GasOracle.start_link([]) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
    end

    :ok
  end

  test "EIP-1559 Optimization Strategies" do
    GasOracle.set_mock_base_fee(50_000_000_000)

    # Economy strategy
    economy = TxManager.optimize_gas_fees(:economy)
    assert economy.max_priority_fee_per_gas == 1_000_000_000
    assert economy.max_fee_per_gas == 101_000_000_000 # (50Gwei * 2) + 1Gwei

    # Fast strategy
    fast = TxManager.optimize_gas_fees(:fast)
    assert fast.max_priority_fee_per_gas == 5_000_000_000
    assert fast.max_fee_per_gas == 105_000_000_000 # (50Gwei * 2) + 5Gwei
  end

  test "Transaction Batching & Reporting" do
    tx1 = %{to: "0x1", data: "0xaa"}
    tx2 = %{to: "0x2", data: "0xbb"}
    tx3 = %{to: "0x3", data: "0xcc"}

    batch = TxManager.batch_transactions([tx1, tx2, tx3])
    
    assert batch.type == :multicall
    assert length(batch.calls) == 3
    assert batch.estimated_gas_saved == 42_000 # 2 txs * 21_000

    report = TxManager.report_savings([tx1, tx2, tx3], batch)
    assert report.original_gas_cost == 63_000
    assert report.batched_gas_cost == 21_000
    assert report.gas_saved == 42_000
    assert report.saved_percentage == 66.67
  end

  test "Transaction Replacement (Speed Up / Cancel)" do
    tx = %{from: "0xA", nonce: 5, max_fee_per_gas: 100_000_000_000, max_priority_fee_per_gas: 2_000_000_000}

    speed_up_tx = TxManager.speed_up(tx)
    assert speed_up_tx.max_fee_per_gas == 110_000_000_000 # 10% bump
    assert speed_up_tx.max_priority_fee_per_gas == 2_200_000_000 # 10% bump
    assert speed_up_tx.nonce == 5

    cancel_tx = TxManager.cancel(tx)
    assert cancel_tx.to == "0xA"
    assert cancel_tx.value == 0
    assert cancel_tx.max_fee_per_gas == 110_000_000_000
    assert cancel_tx.max_priority_fee_per_gas == 2_200_000_000
  end

  test "MEV Protection Wrappers" do
    tx = %{to: "0xB", value: 1000}

    protected_tx = TxManager.protect_transaction(tx, builder: "flashbots", slippage: 0.05)
    
    assert protected_tx.protection_enabled == true
    assert protected_tx.routing == :private
    assert protected_tx.builder == "flashbots"
    assert protected_tx.slippage_tolerance == 0.05
    assert protected_tx.transaction == tx
  end

  test "Transaction Simulation" do
    batch = TxManager.batch_transactions([%{to: "0x1"}, %{to: "0x2"}])
    
    # Base 21000 + 2 * 30000 = 81000
    assert TxManager.delegate_estimate_gas(batch) == 81_000
    
    # Normal Tx = 21000
    assert TxManager.delegate_estimate_gas(%{to: "0x1"}) == 21_000
  end
end
