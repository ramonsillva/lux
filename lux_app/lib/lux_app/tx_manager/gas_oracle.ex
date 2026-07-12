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
    # Default base fee of 30 gwei
    {:ok, %{base_fee: 30.0}}
  end

  @impl true
  def handle_call(:get_base_fee, _from, state) do
    {:reply, state.base_fee, state}
  end

  @impl true
  def handle_cast({:set_base_fee, fee}, state) do
    {:noreply, %{state | base_fee: fee}}
  end
end
