defmodule AshAuthentication.Strategy.Oidc.Verifier do
  @moduledoc """
  DSL verifier for OpenID Connect strategy.
  """

  alias AshAuthentication.Strategy.OAuth2
  import AshAuthentication.Validations

  @doc false
  @spec verify(OAuth2.t(), map) :: :ok | {:error, Exception.t()}
  def verify(strategy, _dsl_state) do
    with :ok <- validate_secret(strategy, :client_id),
         :ok <- validate_secret(strategy, :client_secret, [nil]),
         :ok <- validate_secret(strategy, :base_url),
         :ok <- validate_secret(strategy, :nonce, [true, false]) do
      # OIDC uses `client_authentication_method` (string) for token endpoint auth.
      # Fall back to OAuth2 `auth_method` (atom) if present.
      case {strategy.client_authentication_method, strategy.auth_method} do
        {method, _} when is_binary(method) and method == "private_key_jwt" ->
          validate_secret(strategy, :private_key)

        {_, :private_key_jwt} ->
          validate_secret(strategy, :private_key)

        _ ->
          :ok
      end
    end
  end
end
