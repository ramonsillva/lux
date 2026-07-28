defmodule LuxAppWeb.Auth.MockTokenGater do
  @moduledoc """
  Mock TokenGater adapter strictly for testing environments.
  """
  @behaviour LuxAppWeb.Auth.TokenGater.Adapter

  @impl true
  def has_access?(address, _chain_id, _token_contract) do
    String.downcase(address) == "0x9999999999999999999999999999999999999999"
  end
end
