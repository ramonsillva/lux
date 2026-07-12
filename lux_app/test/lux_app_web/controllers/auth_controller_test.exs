defmodule LuxAppWeb.AuthControllerTest do
  use LuxAppWeb.ConnCase

  describe "GET /api/auth/nonce" do
    test "returns a 32-character hex nonce and sets it in session", %{conn: conn} do
      conn = get(conn, "/api/auth/nonce")
      
      assert %{"nonce" => nonce} = json_response(conn, 200)
      assert String.length(nonce) == 32
      assert get_session(conn, :siwe_nonce) == nonce
    end
  end

  describe "POST /api/auth/verify" do
    setup %{conn: conn} do
      conn = 
        conn
        |> init_test_session(siwe_nonce: "testingnonce1234567890abcdef123456")
        |> Map.put(:host, "www.example.com")
        |> Map.put(:scheme, :http)
        |> Map.put(:port, 80)
      
      %{conn: conn}
    end

    test "fails if missing message or signature", %{conn: conn} do
      conn = post(conn, "/api/auth/verify", %{"message" => "msg"})
      assert %{"error" => "Missing message or signature parameter."} = json_response(conn, 400)
    end

    test "fails with invalid format SIWE message", %{conn: conn} do
      conn = post(conn, "/api/auth/verify", %{"message" => "invalid", "signature" => "0x00"})
      assert %{"error" => "Verification failed", "reason" => "invalid_siwe_message"} = json_response(conn, 401)
    end
    
    test "succeeds with known-valid EIP-4361 deterministic vector", %{conn: conn} do
      valid_message = """
      www.example.com wants you to sign in with your Ethereum account:
      0x97607faAE78d2D3E549B27d90f99F0e9A3BE1B58

      Login to Lux

      URI: http://www.example.com
      Version: 1
      Chain ID: 1
      Nonce: testingnonce1234567890abcdef123456
      Issued At: 2026-07-12T00:00:00Z
      Expiration Time: 2099-12-31T23:59:59Z
      """
      valid_message = String.trim(valid_message)
      valid_signature = "0x2aaedb0b0c2e52e65d2fcaa0c51e51884f3e73b8c87cf41a007f52f2dd9d9e2d12ef40c065e8ae8763ee46c1f10f1b7d57f4926e70e2305df50f41d8a7a2b8b01b"

      conn = post(conn, "/api/auth/verify", %{"message" => valid_message, "signature" => valid_signature})
      assert %{"success" => true, "address" => "0x97607faae78d2d3e549b27d90f99f0e9a3be1b58"} = json_response(conn, 200)
    end

    test "fails with expired message", %{conn: conn} do
      expired_message = """
      www.example.com wants you to sign in with your Ethereum account:
      0x97607faAE78d2D3E549B27d90f99F0e9A3BE1B58

      URI: http://www.example.com
      Version: 1
      Chain ID: 1
      Nonce: testingnonce1234567890abcdef123456
      Issued At: 2021-07-12T00:00:00Z
      Expiration Time: 2021-07-13T00:00:00Z
      """
      expired_message = String.trim(expired_message)
      
      conn = post(conn, "/api/auth/verify", %{"message" => expired_message, "signature" => "0x00"})
      assert %{"error" => "Verification failed", "reason" => "expired_message"} = json_response(conn, 401)
    end

    test "succeeds via multisig EIP-1271 fallback", %{conn: conn} do
      multisig_message = """
      www.example.com wants you to sign in with your Ethereum account:
      0x7777777777777777777777777777777777777777

      URI: http://www.example.com
      Version: 1
      Chain ID: 1
      Nonce: testingnonce1234567890abcdef123456
      Issued At: 2026-07-12T00:00:00Z
      Expiration Time: 2099-12-31T23:59:59Z
      """
      multisig_message = String.trim(multisig_message)
      valid_mock_signature = "0xvalid_eip1271_mock_signature_that_simulates_contract_response"

      conn = post(conn, "/api/auth/verify", %{"message" => multisig_message, "signature" => valid_mock_signature})
      assert %{"success" => true, "address" => "0x7777777777777777777777777777777777777777"} = json_response(conn, 200)
    end
  end

  describe "Token Gating via ProfileController" do
    test "denies access to normal wallet", %{conn: conn} do
      conn = 
        conn
        |> init_test_session(web3_address: "0x1111111111111111111111111111111111111111")
        |> get("/api/profile")
        
      assert %{"error" => "Insufficient token balance for premium access."} = json_response(conn, 403)
    end

    test "allows access to VIP wallet", %{conn: conn} do
      conn = 
        conn
        |> init_test_session(web3_address: "0x9999999999999999999999999999999999999999")
        |> get("/api/profile")
        
      assert %{"premium_access" => true} = json_response(conn, 200)
    end
  end

  describe "POST /api/auth/logout" do
    test "clears session", %{conn: conn} do
      conn = 
        conn
        |> init_test_session(web3_address: "0x123", role: "user")
        
      assert get_session(conn, :web3_address) == "0x123"
      
      conn = post(conn, "/api/auth/logout")
      assert %{"success" => true} = json_response(conn, 200)
      
      assert get_session(conn, :web3_address) == nil
    end
  end
end
