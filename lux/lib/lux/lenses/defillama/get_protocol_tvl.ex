defmodule Lux.Lenses.DefiLlama.GetProtocolTvl do
  @moduledoc """
  Lens for fetching a protocol's TVL and historical metrics from DeFiLlama.
  """

  use Lux.Lens,
    name: "DeFiLlama Protocol TVL API",
    description: "Fetches historical TVL and protocol metrics from DeFiLlama",
    url: "https://api.llama.fi/protocol/{protocol}",
    method: :get,
    headers: [{"accept", "application/json"}],
    schema: %{
      type: :object,
      properties: %{
        protocol: %{
          type: :string,
          description: "Protocol slug (e.g. 'lido', 'aave', 'uniswap')"
        }
      },
      required: ["protocol"]
    }

  @doc """
  Transforms the API response into a more usable format.
  """
  @impl true
  def after_focus(response) when is_map(response) do
    if Map.has_key?(response, "tvl") do
      transformed = %{
        name: response["name"],
        symbol: response["symbol"],
        tvl: response["tvl"],
        historical_tvl: response["chainTvls"]
      }
      {:ok, transformed}
    else
      if Map.has_key?(response, "message") do
        {:error, response["message"]}
      else
        {:error, "Invalid response from DeFiLlama"}
      end
    end
  end
end
