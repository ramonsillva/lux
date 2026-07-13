defmodule LuxApp.TxManagerTest do
  use ExUnit.Case

  alias LuxApp.TxManager
  alias LuxApp.TxManager.GasOracle

  # GasOracle is now properly supervised by LuxApp.Application
  # No manual start_link required here.

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
    
    assert batch.to == "0xcA11bde05977b3631167028862bE2a173976CA11"
    assert batch.estimated_gas_saved == 42_000 # 2 txs * 21_000

    report = TxManager.report_savings([tx1, tx2, tx3], batch)
    assert report.original_gas_cost == 63_000
    assert report.batched_gas_cost == 21_000
    assert report.gas_saved == 42_000
    assert report.saved_percentage == 66.67
    
    empty_report = TxManager.report_savings([], batch)
    assert empty_report.gas_saved == 0
  end

  test "Transaction Replacement (Speed Up / Cancel) with RPC submission" do
    tx = %{from: "0xA", nonce: 5, max_fee_per_gas: 100_000_000_000, max_priority_fee_per_gas: 2_000_000_000}

    {:ok, _hash, speed_up_tx} = TxManager.speed_up(tx)
    assert speed_up_tx.max_fee_per_gas == 110_000_000_000 # 10% bump
    assert speed_up_tx.max_priority_fee_per_gas == 2_200_000_000 # 10% bump
    assert speed_up_tx.nonce == 5

    {:ok, _hash, cancel_tx} = TxManager.cancel(tx)
    assert cancel_tx.to == "0xA"
    assert cancel_tx.value == 0
    assert cancel_tx.max_fee_per_gas == 110_000_000_000
    assert cancel_tx.max_priority_fee_per_gas == 2_200_000_000
  end

  test "MEV Protection Wrappers via RPC" do
    tx = %{to: "0xB", value: 1000}

    {:ok, _hash, metadata} = TxManager.protect_transaction(tx, builder: "flashbots", slippage: 0.05)
    
    assert metadata.protection_enabled == true
    assert metadata.routing == :private
    assert metadata.builder == "flashbots"
    assert metadata.slippage_tolerance == 0.05
  end

  test "Transaction Simulation via RPC" do
    batch = TxManager.batch_transactions([%{to: "0x1"}, %{to: "0x2"}])
    assert {:ok, 21_000} = TxManager.delegate_estimate_gas(batch)
    
    assert {:error, :execution_reverted} = TxManager.delegate_estimate_gas(%{to: "0xbad"})
  end
  
  test "Gas Token integration" do
    tx = %{data: "0x123"}
    wrapped = LuxApp.TxManager.GasToken.wrap_with_gas_token(tx, "0xCHI", 10)
    assert wrapped.data == "0x123_freeFromUpTo(0xCHI,10)"
  end
end
