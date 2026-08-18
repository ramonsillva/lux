defmodule LuxApp.TxManagerTest do
  use ExUnit.Case

  alias LuxApp.TxManager
  alias LuxApp.TxManager.{GasOracle, ABIEncoder, GasToken}

  test "EIP-1559 Optimization Strategies" do
    GasOracle.set_mock_base_fee(50_000_000_000)

    {:ok, economy} = TxManager.optimize_gas_fees(:economy)
    assert economy.max_priority_fee_per_gas == 1_000_000_000
    assert economy.max_fee_per_gas == 101_000_000_000

    {:ok, fast} = TxManager.optimize_gas_fees(:fast)
    assert fast.max_priority_fee_per_gas == 5_000_000_000
    assert fast.max_fee_per_gas == 105_000_000_000
  end

  test "Transaction Batching & Multicall3 ABI Encoding" do
    tx1 = %{to: "0x1111111111111111111111111111111111111111", data: "0xaabbccdd"}
    tx2 = %{to: "0x2222222222222222222222222222222222222222", data: "0x11223344"}

    batch = TxManager.batch_transactions([tx1, tx2])
    
    assert batch.to == "0xcA11bde05977b3631167028862bE2a173976CA11"
    assert String.starts_with?(batch.data, "0x82ad56cb") # Multicall3 aggregate3 selector
    assert batch.estimated_gas_saved == 21_000

    report = TxManager.report_savings([tx1, tx2], batch)
    assert report.original_gas_cost == 42_000
    assert report.batched_gas_cost == 21_000
    assert report.gas_saved == 21_000
  end

  test "ABIEncoder exact zero-length bytes encoding" do
    # Empty bytes data must have 0 tail padding
    assert ABIEncoder.pad_bytes_right("") == ""
    assert ABIEncoder.pad_bytes_right("0x") == ""

    # Non-empty bytes must be padded to 32-byte boundary
    assert ABIEncoder.pad_bytes_right("0xaabb") == "aabb000000000000000000000000000000000000000000000000000000000000"
  end

  test "Transaction Replacement (Speed Up / Cancel) generates signed raw_tx with bumped fees" do
    tx = %{from: "0x000000000000000000000000000000000000000A", nonce: 5, max_fee_per_gas: 100_000_000_000, max_priority_fee_per_gas: 2_000_000_000}

    {:ok, _hash, speed_up_tx} = TxManager.speed_up(tx)
    assert speed_up_tx.max_fee_per_gas == 110_000_000_000 # 10% bump
    assert speed_up_tx.max_priority_fee_per_gas == 2_200_000_000 # 10% bump
    assert speed_up_tx.nonce == 5
    assert is_binary(speed_up_tx.raw_tx)
    assert speed_up_tx.raw_tx != "0x"
    assert String.starts_with?(speed_up_tx.raw_tx, "0x02") # EIP-1559 Type 2 envelope

    {:ok, _hash, cancel_tx} = TxManager.cancel(tx)
    assert cancel_tx.to == "0x000000000000000000000000000000000000000A"
    assert cancel_tx.value == 0
    assert cancel_tx.max_fee_per_gas == 110_000_000_000
    assert cancel_tx.max_priority_fee_per_gas == 2_200_000_000
    assert is_binary(cancel_tx.raw_tx)
    assert cancel_tx.raw_tx != "0x"
    assert String.starts_with?(cancel_tx.raw_tx, "0x02")
  end

  test "Transaction Replacement bounded retries on underpriced error" do
    tx = %{from: "0xA", nonce: 5, max_fee_per_gas: 100_000_000_000, max_priority_fee_per_gas: 2_000_000_000, simulated_error: :replacement_underpriced}

    assert {:error, :max_replacement_retries_exceeded} = TxManager.speed_up(tx)
  end

  test "MEV Protection Wrappers via RPC" do
    tx = %{to: "0xB", value: 1000}

    {:ok, _hash, metadata} = TxManager.protect_transaction(tx, builder: "flashbots", slippage: 0.05)
    
    assert metadata.protection_enabled == true
    assert metadata.routing == :private
    assert metadata.builder == "flashbots"
    assert metadata.slippage_tolerance == 0.05
  end

  test "Gas Token Multicall3 bundle" do
    tx = %{to: "0x1111111111111111111111111111111111111111", data: "0x1234"}
    wrapped = GasToken.wrap_with_gas_token(tx, "0x2222222222222222222222222222222222222222", 10)
    
    assert wrapped.to == "0xcA11bde05977b3631167028862bE2a173976CA11" # Multicall3 contract
    assert String.starts_with?(wrapped.data, "0x82ad56cb") # aggregate3 selector
    assert String.contains?(wrapped.data, "d7db9b35") # freeFromUpTo selector embedded inside Call 1
  end

  test "Production RPCAdapter configuration contract wiring" do
    assert Application.get_env(:lux_app, :rpc_adapter) != nil
  end
end
