defmodule LuxAppWeb.Auth.SessionManager do
  @moduledoc """
  Session lifecycle management and TTL expiration enforcing for Web3 authentication.

  ## Examples

      # Initialize a fresh Web3 session
      conn = LuxAppWeb.Auth.SessionManager.init_session(conn, "0x123...", "user")

      # Validate session TTL (24h default)
      case LuxAppWeb.Auth.SessionManager.validate_session(conn) do
        {:ok, conn} -> proceed(conn)
        {:error, :session_expired} -> reject(conn)
      end
  """

  import Plug.Conn

  @default_ttl 86_400 # 24 hours in seconds

  @doc """
  Initializes session keys including creation timestamp and expiration time.
  """
  def init_session(conn, address, role \\ "user", ttl \\ @default_ttl) do
    now = System.system_time(:second)
    expires_at = now + ttl

    conn
    |> put_session(:web3_address, address)
    |> put_session(:role, role)
    |> put_session(:authenticated_at, now)
    |> put_session(:expires_at, expires_at)
  end

  @doc """
  Validates whether the current session is active and not expired.
  Returns `{:ok, conn}` if valid, or `{:error, :session_expired}` if expired or missing.
  """
  def validate_session(conn) do
    expires_at = get_session(conn, :expires_at)
    now = System.system_time(:second)

    cond do
      is_nil(expires_at) ->
        {:error, :unauthenticated}

      now > expires_at ->
        conn = clear_session(conn)
        {:error, :session_expired}

      true ->
        {:ok, conn}
    end
  end

  @doc """
  Renews the session TTL by resetting the expiration timestamp.
  """
  def renew_session(conn, ttl \\ @default_ttl) do
    case get_session(conn, :web3_address) do
      nil -> {:error, :unauthenticated}
      address ->
        role = get_session(conn, :role) || "user"
        {:ok, init_session(conn, address, role, ttl)}
    end
  end
end
