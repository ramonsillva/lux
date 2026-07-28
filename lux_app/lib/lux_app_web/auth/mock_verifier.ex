defmodule LuxAppWeb.Auth.MockVerifier do
  @moduledoc """
  A mock EIP-1271 verifier strictly for testing environments.
  """
  @behaviour LuxAppWeb.Auth.EIP1271Verifier

  @impl true
  def is_valid_signature?(_message, signature, expected_address) do
    # Simulates success if the signature matches test vector
    String.downcase(expected_address) == "0x7777777777777777777777777777777777777777" and
      signature == "0xvalid_eip1271_mock_signature_that_simulates_contract_response"
  end
end
