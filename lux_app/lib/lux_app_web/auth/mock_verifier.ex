defmodule LuxAppWeb.Auth.MockVerifier do
  @moduledoc """
  A mock EIP-1271 verifier for testing fallback.
  """
  
  def is_valid_signature?(_message, signature, expected_address) do
    # Simula sucesso se a assinatura for uma flag especial de teste
    # e o endereço for o endereço de teste multisig
    String.downcase(expected_address) == "0xmultisig000000000000000000000000000000" and
      signature == "0xvalid_eip1271_mock_signature_that_simulates_contract_response"
  end
end
