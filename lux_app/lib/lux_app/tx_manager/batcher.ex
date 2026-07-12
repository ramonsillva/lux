defmodule LuxApp.TxManager.Batcher do
  @moduledoc """
  Transaction batching implementation to save base gas costs.
  """

  @doc """
  Groups multiple transaction payloads into a single multicall structure.
  Saves 21,000 gas per additional transaction batched.
  """
  def create_multicall(transactions) when is_list(transactions) do
    if length(transactions) == 0 do
      {:error, :empty_batch}
    else
      %{
        type: :multicall,
        calls: transactions,
        estimated_gas_saved: (length(transactions) - 1) * 21_000
      }
    end
  end
end
