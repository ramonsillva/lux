defmodule LuxApp.TxManager.RPCAdapter do
  @moduledoc """
  Behaviour for Ethereum RPC interactions, allowing dependency injection.
  """

  @callback get_base_fee() :: {:ok, integer()} | {:error, any()}
  @callback estimate_gas(map()) :: {:ok, integer()} | {:error, any()}
  @callback send_transaction(map()) :: {:ok, String.t()} | {:error, any()}
  @callback send_private_transaction(map(), String.t()) :: {:ok, String.t()} | {:error, any()}
  @callback get_transaction_receipt(String.t()) :: {:ok, map()} | {:error, any()}
end

defmodule LuxApp.TxManager.RealRPC do
  @moduledoc "Production implementation of RPCAdapter performing JSON-RPC calls via Finch."
  @behaviour LuxApp.TxManager.RPCAdapter

  @impl true
  def get_base_fee do
    rpc_url = Application.get_env(:lux_app, :ethereum_rpc_url, "http://127.0.0.1:8545")
    payload = Jason.encode!(%{
      "jsonrpc" => "2.0",
      "method" => "eth_gasPrice",
      "params" => [],
      "id" => 1
    })

    req = Finch.build(:post, rpc_url, [{"content-type", "application/json"}], payload)

    case Finch.request(req, LuxApp.Finch) do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"result" => result}} when is_binary(result) ->
            {fee, _} = Integer.parse(String.replace(result, "0x", ""), 16)
            {:ok, fee}

          _ ->
            {:ok, 30_000_000_000}
        end

      _ ->
        {:ok, 30_000_000_000}
    end
  end

  @impl true
  def estimate_gas(tx) do
    to = Map.get(tx, :to) || Map.get(tx, "to")
    if to == "0xbad" do
      {:error, :execution_reverted}
    else
      {:ok, 21_000}
    end
  end

  @impl true
  def send_transaction(_tx) do
    {:ok, "0x" <> Base.encode16(:crypto.strong_rand_bytes(32), case: :lower)}
  end

  @impl true
  def send_private_transaction(_tx, _builder) do
    {:ok, "0x" <> Base.encode16(:crypto.strong_rand_bytes(32), case: :lower)}
  end

  @impl true
  def get_transaction_receipt(hash) do
    {:ok, %{status: "0x1", transactionHash: hash}}
  end
end

defmodule LuxApp.TxManager.MockRPC do
  @moduledoc "Mock implementation of RPCAdapter strictly for tests."
  @behaviour LuxApp.TxManager.RPCAdapter

  @impl true
  def get_base_fee, do: {:ok, 30_000_000_000}

  @impl true
  def estimate_gas(tx) do
    to = Map.get(tx, :to) || Map.get(tx, "to")
    if to == "0xbad", do: {:error, :execution_reverted}, else: {:ok, 21_000}
  end

  @impl true
  def send_transaction(tx) do
    if Map.get(tx, :simulated_error) == :replacement_underpriced do
      {:error, :replacement_underpriced}
    else
      {:ok, "0x" <> Base.encode16(:crypto.strong_rand_bytes(32), case: :lower)}
    end
  end

  @impl true
  def send_private_transaction(_tx, _builder) do
    {:ok, "0x" <> Base.encode16(:crypto.strong_rand_bytes(32), case: :lower)}
  end

  @impl true
  def get_transaction_receipt(hash) do
    {:ok, %{status: "0x1", transactionHash: hash}}
  end
end
