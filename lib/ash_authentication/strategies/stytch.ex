defmodule AshAuthentication.Strategy.Stytch do
  alias __MODULE__.Dsl

  @moduledoc """
  Stytch Connected Apps authentication strategy.

  This strategy wraps the OIDC strategy with defaults tailored for
  [Stytch Connected Apps](https://stytch.com/docs/guides/connected-apps/mcp-server-overview).
  Use it when Stytch acts as your OAuth 2.1 / OIDC authorization server and
  provides Dynamic Client Registration for MCP clients.

  The strategy builds on `AshAuthentication.Strategy.Oidc`, so all options from
  that strategy remain available. The Stytch wrapper adjusts defaults so that
  `base_url` points at your project domain (for example,
  `https://example-app.customers.stytch.com`) and the discovery document is
  fetched from Stytch's OAuth authorization server metadata endpoint
  (`/.well-known/oauth-authorization-server`).

  Note on discovery: Stytch exposes OAuth 2.1 Authorization Server metadata,
  which differs from the standard OIDC provider discovery path
  `/.well-known/openid-configuration`. Assent and this strategy only require the
  standard authorization, token, JWKS, and issuer fields, which are present in
  Stytch's Authorization Server metadata, so this default is intentional.

  ### Minimum configuration

    * `client_id`
    * `client_secret`
    * `base_url` – your Stytch project domain (`https://<project>.customers.stytch.com` or a custom domain)
    * `redirect_uri`

  For full compliance with MCP 2025-06-18 you should also set `authorization_params`
  to include a `resource` indicator and scopes that match your MCP server.

  See the Stytch Connected Apps guide and the OIDC strategy documentation for
  additional configuration details.
  """

  alias AshAuthentication.Strategy.Custom

  use Custom, entity: Dsl.dsl()

  @doc false
  defdelegate dsl, to: Dsl
  defdelegate transform(strategy, dsl_state), to: __MODULE__.Transformer
  defdelegate verify(strategy, dsl_state), to: __MODULE__.Verifier
end
