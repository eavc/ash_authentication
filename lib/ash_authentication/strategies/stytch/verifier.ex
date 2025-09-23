defmodule AshAuthentication.Strategy.Stytch.Verifier do
  @moduledoc """
  DSL verifier for the Stytch strategy.

  Inherits the default OIDC validations.
  """

  alias AshAuthentication.Strategy.Oidc

  @doc false
  @spec verify(struct, map) :: :ok | {:error, Exception.t()}
  def verify(strategy, dsl_state) do
    Oidc.Verifier.verify(strategy, dsl_state)
  end
end
