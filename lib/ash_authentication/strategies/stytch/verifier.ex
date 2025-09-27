defmodule AshAuthentication.Strategy.Stytch.Verifier do
  @moduledoc """
  DSL verifier for the Stytch strategy.

  Inherits the default OIDC validations.
  """

  require Logger
  alias AshAuthentication.Strategy.Oidc

  @doc false
  @spec verify(struct, map) :: :ok | {:error, Exception.t()}
  def verify(strategy, dsl_state) do
    with :ok <- Oidc.Verifier.verify(strategy, dsl_state) do
      maybe_warn_missing_audience(strategy)
      :ok
    end
  end

  defp maybe_warn_missing_audience(%{resource_indicator: resource, trusted_audiences: audiences})
       when is_binary(resource) and is_list(audiences) do
    unless resource in audiences do
      Logger.warning("""
      [AshAuthentication.Stytch] `resource_indicator` #{inspect(resource)} is not present in
      `trusted_audiences`. The strategy now appends it at runtime for safety, but you should keep the
      values aligned to avoid surprise configuration drift.
      """)
    end
  end

  defp maybe_warn_missing_audience(_strategy), do: :ok
end
