defmodule LuxAppWeb.Auth.Siwe do
  @moduledoc """
  SIWE (Sign-In with Ethereum) EIP-4361 verification logic.
  Handles full payload parsing, field validation, and cryptographic signature verification.
  """

  def verify_signature(message, signature, expected_nonce, expected_domain, expected_uri) do
    with {:ok, parsed} <- parse_message(message),
         :ok <- verify_domain(parsed.domain, expected_domain),
         :ok <- verify_uri(parsed.uri, expected_uri),
         :ok <- verify_nonce(parsed.nonce, expected_nonce),
         :ok <- verify_expiration(parsed.expiration_time),
         :ok <- check_signature(message, signature, parsed.address) do
      {:ok, parsed.address}
    else
      err -> err
    end
  end

  def parse_message(message) do
    # Extração robusta baseada na EIP-4361
    regex = ~r/^(?<domain>[a-zA-Z0-9\.-]+) wants you to sign in with your Ethereum account:\n(?<address>0x[a-fA-F0-9]{40})\n\n(?<statement>.*?)\n\nURI: (?<uri>.*?)\nVersion: (?<version>\d+)\nChain ID: (?<chain_id>\d+)\nNonce: (?<nonce>[a-zA-Z0-9]+)\nIssued At: (?<issued_at>.*?)(?:\nExpiration Time: (?<expiration_time>.*?))?(?:\n|$)/s

    case Regex.named_captures(regex, message) do
      nil -> {:error, :invalid_siwe_message}
      captures ->
        {:ok, %{
          domain: captures["domain"],
          address: String.downcase(captures["address"]),
          statement: captures["statement"],
          uri: captures["uri"],
          version: captures["version"],
          chain_id: captures["chain_id"],
          nonce: captures["nonce"],
          issued_at: captures["issued_at"],
          expiration_time: if(captures["expiration_time"] == "", do: nil, else: captures["expiration_time"])
        }}
    end
  end

  def verify_domain(domain, expected_domain) do
    if domain == expected_domain, do: :ok, else: {:error, :domain_mismatch}
  end

  def verify_uri(uri, expected_uri) do
    if uri == expected_uri, do: :ok, else: {:error, :uri_mismatch}
  end

  def verify_nonce(nonce, expected_nonce) do
    if nonce == expected_nonce, do: :ok, else: {:error, :nonce_mismatch}
  end

  def verify_expiration(nil), do: :ok
  def verify_expiration(expiration_time) do
    case DateTime.from_iso8601(expiration_time) do
      {:ok, exp_dt, _offset} ->
        if DateTime.compare(exp_dt, DateTime.utc_now()) == :gt do
          :ok
        else
          {:error, :expired_message}
        end
      _ ->
        {:error, :invalid_expiration_format}
    end
  end

  def check_signature(message, signature, expected_address) do
    message_length = byte_size(message)
    eth_message = "\x19Ethereum Signed Message:\n#{message_length}#{message}"
    
    hash = ExKeccak.hash_256(eth_message)
    sig_bytes = Base.decode16!(String.replace(signature, "0x", ""), case: :mixed)
    
    if byte_size(sig_bytes) == 65 do
      <<r::binary-size(32), s::binary-size(32), v::integer>> = sig_bytes
      recovery_id = if v >= 27, do: v - 27, else: v
      
      case ExSecp256k1.recover(hash, r <> s, recovery_id) do
        {:ok, pubkey} ->
          <<4::integer, uncompressed_pubkey::binary-size(64)>> = pubkey
          pub_hash = ExKeccak.hash_256(uncompressed_pubkey)
          
          <<_::binary-size(12), address_bytes::binary-size(20)>> = pub_hash
          recovered_address = "0x" <> Base.encode16(address_bytes, case: :lower)
          
          if String.downcase(expected_address) == recovered_address do
            :ok
          else
            check_multisig_fallback(message, signature, expected_address)
          end
        _ ->
          {:error, :recovery_failed}
      end
    else
      {:error, :invalid_signature_length}
    end
  rescue
    _ -> {:error, :signature_verification_crashed}
  end

  # EIP-1271 Fallback implementation stub for Smart Contract wallets
  defp check_multisig_fallback(_message, _signature, _expected_address) do
    # Here we would typically call an RPC endpoint to verify the EIP-1271 signature
    # Since we avoid vendor lock-in, we simulate the structure of an on-chain fallback
    {:error, :invalid_signature_and_no_multisig_fallback_configured}
  end
end
