defmodule AshAuthentication.Strategy.Stytch.Transformer do
  @moduledoc """
  DSL transformer for the Stytch strategy.

  Delegates to the OIDC transformer and ensures the provider is tagged as
  `:stytch`.
  """

  alias AshAuthentication.Strategy
  alias AshAuthentication.Strategy.{OAuth2, Oidc}
  alias Spark.Dsl.Transformer
  import AshAuthentication.Strategy.Custom.Helpers, only: [put_strategy: 2]

  @doc false
  @spec transform(struct, map) :: {:ok, struct | map} | {:error, Exception.t()}
  def transform(strategy, dsl_state) do
    strategy =
      strategy
      |> Map.put(:provider, :stytch)
      |> Map.put(:icon, :stytch)

    case Oidc.Transformer.transform(strategy, dsl_state) do
      {:ok, %OAuth2{} = transformed} ->
        {:ok,
         transformed
         |> Map.put(:provider, :stytch)
         |> Map.put(:icon, :stytch)}

      {:ok, transformed_dsl_state} when is_map(transformed_dsl_state) ->
        {:ok, ensure_strategy_tagged(transformed_dsl_state, Strategy.name(strategy))}

      other ->
        other
    end
  end

  defp ensure_strategy_tagged(dsl_state, strategy_name) do
    dsl_state
    |> Transformer.get_entities([:authentication, :strategies])
    |> Enum.find(&(Strategy.name(&1) == strategy_name))
    |> case do
      nil ->
        dsl_state

      strategy ->
        strategy =
          strategy
          |> Map.put(:provider, :stytch)
          |> Map.put(:icon, :stytch)

        put_strategy(dsl_state, strategy)
    end
  end
end
