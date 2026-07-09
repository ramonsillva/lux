defmodule Lux.Lenses.Dune.ExecuteQuery do
  @moduledoc """
  Lens for executing a custom query on Dune Analytics (v2 API).
  """

  use Lux.Lens,
    name: "Dune Execute Query API",
    description: "Executes a Dune Analytics query by ID and retrieves execution ID.",
    url: "https://api.dune.com/api/v1/query/{query_id}/execute",
    method: :post,
    headers: [{"content-type", "application/json"}, {"accept", "application/json"}],
    auth: %{
      type: :custom,
      auth_function: &Lux.Integrations.Dune.authenticate/1
    },
    schema: %{
      type: :object,
      properties: %{
        query_id: %{
          type: :integer,
          description: "The ID of the Dune query to execute"
        },
        query_parameters: %{
          type: :object,
          description: "Optional parameters to pass to the query"
        }
      },
      required: ["query_id"]
    }

  @doc """
  Transforms the API response into a more usable format.
  """
  @impl true
  def after_focus(%{"execution_id" => execution_id, "state" => state}) do
    {:ok, %{execution_id: execution_id, state: state}}
  end

  @impl true
  def after_focus(%{"error" => error}) do
    {:error, error}
  end

  @impl true
  def after_focus(response) do
    {:error, "Unexpected response from Dune: #{inspect(response)}"}
  end
end
