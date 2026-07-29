defmodule LuxApp.TxManager.GasToken do
  @moduledoc """
  Integrates Gas Tokens (CHI/GST2) to reduce transaction costs by freeing storage.
  """

  @doc """
  Wraps a transaction to include a call to free up to `amount` of gas tokens.
  """
  def wrap_with_gas_token(tx, token_address, amount) do
    current_data = Map.get(tx, :data, "0x")
    %{tx | data: append_free_from_up_to(current_data, token_address, amount)}
  end

  defp append_free_from_up_to(original_data, token_address, amount) do
    "#{original_data}_freeFromUpTo(#{token_address},#{amount})"
  end
end
