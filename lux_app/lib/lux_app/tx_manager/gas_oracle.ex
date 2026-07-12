defmodule LuxApp.TxManager.GasOracle do
  use GenServer
  
  @moduledoc """
  Gas price prediction system and base fee cache.
  """

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def get_current_base_fee do
    # Simulates an RPC call to get the current base fee in gwei
    GenServer.call(__MODULE__, :get_base_fee)
  end

  def set_mock_base_fee(fee) do
    GenServer.cast(__MODULE__, {:set_base_fee, fee})
  end

  @impl true
  def init(_opts) do
    # Initializes with a base fee (e.g., 30 gwei in wei)
    {:ok, %{base_fee: 30_000_000_000, history: []}}
  end

  @impl true
  def handle_call(:get_base_fee, _from, state) do
    {:reply, state.base_fee, state}
  end

  @impl true
  def handle_cast({:set_base_fee, fee}, state) do
    {:noreply, %{state | base_fee: fee}}
  end

  @doc """
  Updates the base fee using an Exponential Moving Average (EMA) to predict short-term trends.
  """
  def update_with_ema(new_block_base_fee) do
    GenServer.cast(__MODULE__, {:update_ema, new_block_base_fee})
  end

  @impl true
  def handle_cast({:update_ema, new_fee}, state) do
    # Alpha 0.3 for EMA smoothing
    ema_fee = trunc((new_fee * 0.3) + (state.base_fee * 0.7))
    {:noreply, %{state | base_fee: ema_fee, history: [new_fee | Enum.take(state.history, 9)]}}
  end
end
