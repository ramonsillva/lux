defmodule LuxAppWeb.Auth.AuditLogger do
  @moduledoc """
  Audit logger for Web3 authentication attempts and security events.
  """
  require Logger

  def log_login_success(address, chain_id) do
    Logger.info("[AUTH_AUDIT] Success: address=#{address} chain_id=#{chain_id}")
  end

  def log_login_failure(address, reason) do
    Logger.warning("[AUTH_AUDIT] Failure: address=#{address} reason=#{inspect(reason)}")
  end
end
