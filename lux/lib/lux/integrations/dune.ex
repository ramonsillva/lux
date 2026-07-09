defmodule Lux.Integrations.Dune do
  @moduledoc """
  Integration with Dune Analytics API.

  Allows fetching query results and running queries using the Dune v2 API.
  """

  @doc """
  Gets the configured Dune base URL.
  """
  @spec base_url() :: String.t()
  def base_url do
    "https://api.dune.com/api/v1"
  end

  @doc """
  Gets the default headers for Dune API requests.
  """
  @spec headers() :: [{String.t(), String.t()}]
  def headers do
    [
      {"content-type", "application/json"},
      {"accept", "application/json"}
    ]
  end

  @doc """
  Gets the authentication configuration for Dune API requests.
  """
  @spec auth() :: map()
  def auth do
    %{
      type: :api_key,
      key: &__MODULE__.api_key/0
    }
  end

  @doc """
  Authenticates a lens for Dune API requests.
  """
  @spec authenticate(map()) :: map()
  def authenticate(%{headers: headers} = lens) do
    case Enum.find(headers, fn {key, _} -> String.downcase(key) == "x-dune-api-key" end) do
      nil ->
        %{lens | headers: [{"x-dune-api-key", api_key()} | headers]}
      _ ->
        lens
    end
  end

  # Gets the Dune API key from configuration.
  @spec api_key() :: String.t()
  def api_key do
    :lux
    |> Application.get_env(__MODULE__)
    |> Keyword.get(:api_key, System.get_env("DUNE_API_KEY"))
  end
end
