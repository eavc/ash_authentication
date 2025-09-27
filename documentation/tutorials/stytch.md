# Stytch Tutorial

This tutorial walks through integrating [Stytch Connected Apps](https://stytch.com/docs/guides/connected-apps/mcp-server-overview) with `AshAuthentication` using the `stytch` strategy.

## Create a Stytch Connected App

1. Sign in to the [Stytch dashboard](https://stytch.com/dashboard) and choose the project that should back your MCP server.
2. Navigate to **Connected Apps → MCP Server** and create a new MCP server (or use an existing one).
3. Copy the **Client ID**, **Client Secret**, and **Project Domain**. You will need all three in your Elixir configuration.
4. Add an **Allowed Redirect URL** that points at the callback route AshAuthentication generates. It has the shape `https://your-app.com/auth/<subject>/stytch/callback`.
5. (Optional but recommended) Configure a **Resource indicator** value that represents your MCP server. You will provide this value through the strategy’s `resource_indicator` option.

> ### HTTPS strongly recommended {: .tip }
> Stytch expects production callback URLs to use HTTPS. During local development you can tunnel a local Phoenix server through a tool like [ngrok](https://ngrok.com/) and register that HTTPS URL.

## Configure the strategy

Add the strategy to the `authentication` block of your resource. The `base_url` should be the project domain you copied earlier (it usually looks like `https://<project>.customers.stytch.com` or a custom domain you configured).

```elixir
defmodule MyApp.Accounts.User do
  use Ash.Resource,
    extensions: [AshAuthentication],
    domain: MyApp.Accounts

  authentication do
    strategies do
      stytch do
        client_id MyApp.StytchSecrets
        client_secret MyApp.StytchSecrets
        redirect_uri MyApp.StytchSecrets
        base_url MyApp.StytchSecrets
        trusted_audiences MyApp.StytchSecrets
        authorization_params scope: "openid profile email"
        resource_indicator MyApp.StytchSecrets
      end
    end
  end
end
```

The strategy inherits every option from the underlying `oidc` strategy, so you can override discovery behaviour or disable registration exactly like any other OpenID Connect provider.

### Manage secrets with `AshAuthentication.Secret`

Create a secret provider module to fetch credentials from your configuration or secret store:

```elixir
defmodule MyApp.StytchSecrets do
  use AshAuthentication.Secret

  def secret_for([:authentication, :strategies, :stytch, :client_id], MyApp.Accounts.User, _opts),
    do: fetch(:client_id)

  def secret_for([:authentication, :strategies, :stytch, :client_secret], MyApp.Accounts.User, _opts),
    do: fetch(:client_secret)

  def secret_for([:authentication, :strategies, :stytch, :redirect_uri], MyApp.Accounts.User, _opts),
    do: fetch(:redirect_uri)

  def secret_for([:authentication, :strategies, :stytch, :base_url], MyApp.Accounts.User, _opts),
    do: fetch(:base_url)

  def secret_for([:authentication, :strategies, :stytch, :trusted_audiences], MyApp.Accounts.User, _opts),
    do: fetch(:trusted_audiences)

  def secret_for([:authentication, :strategies, :stytch, :resource_indicator], MyApp.Accounts.User, _opts),
    do: fetch(:resource_indicator)

  defp fetch(key) do
    :my_app
    |> Application.get_env(:stytch, [])
    |> Keyword.fetch!(key)
  end
end
```

Populate the application environment (or an alternative secret backend) with the values you copied from Stytch. For `trusted_audiences`, use the expected audience claim for your MCP server, and for `resource_indicator` supply the MCP resource URI (for example, `https://example.com/mcp`).

## Register action

If `registration_enabled?` is `true` (the default), you must provide a registration action. The Stytch strategy expects the action to be an upsert that accepts both `user_info` and `oauth_tokens` arguments, mirroring the standard OAuth flow:

```elixir
defmodule MyApp.Accounts.User do
  # ...

  actions do
    create :register_with_stytch do
      argument :user_info, :map, allow_nil?: false
      argument :oauth_tokens, :map, allow_nil?: false
      upsert? true
      upsert_identity :email

      change AshAuthentication.GenerateTokenChange
      change AshAuthentication.Strategy.OAuth2.IdentityChange

      change fn changeset, _ctx ->
        user_info = Ash.Changeset.get_argument(changeset, :user_info)

        changeset
        |> Ash.Changeset.change_attribute(:email, user_info["email"])
      end
    end
  end

  # ...
end
```

Adjust the upsert identity and attribute mapping to fit your schema. If you are also using the password strategy, remember to allow `hashed_password` to be `nil` so users can exist without a local password.

## Optional: sign-in only

To disable self-service registration, set `registration_enabled? false` on the strategy and provide a sign-in action named `sign_in_with_stytch` (or override `sign_in_action_name`). The sign-in action should locate an existing user based on the Stytch profile and return `{:ok, user}` when successful.

With these pieces in place your application can authenticate users through Stytch while still leveraging all of the AshAuthentication tooling.

## Using Stytch with MCP

When using Stytch to authorize Remote MCP servers, there are a few extra pieces to put in place outside of your AshAuthentication configuration:

- Expose PRM: Serve a Protected Resource Metadata (PRM) document at `/.well-known/oauth-protected-resource` from your MCP server. It should include:
  - `resource` – a stable URI that identifies your MCP server (e.g. `https://example.com/mcp`).
  - `authorization_servers` – an array with your Stytch issuer (your project domain).
  - `scopes_supported` – the scopes your MCP server understands (e.g. `openid`, `profile`, `email`, plus any resource-specific scopes).

- Resource indicator: Configure the same `resource` value on the strategy’s `resource_indicator` option. AshAuthentication injects it automatically into both the authorization and token requests so MCP clients comply with RFC 8707 without extra boilerplate.

- Dynamic Client Registration (DCR): MCP clients obtain `client_id`/`client_secret` by registering against Stytch’s DCR endpoint. This is handled by the MCP client and Stytch — you only reference those credentials in your server via `AshAuthentication.Secret`.

- Audience validation: Tokens issued by Stytch include an `aud` claim. Ensure `trusted_audiences` contains the same `resource_indicator` value (you'll see a compile-time warning if it does not). At runtime the Assent verifier will reject tokens whose `aud` is not in that list, so keep it in sync with the PRM document.

- Validate access tokens: Stytch does not expose an introspection endpoint. Your MCP server must fetch Stytch's JWKS and validate JWT signatures and claims locally (e.g. with `Joken`). Verify `aud`, `iss`, `exp`, and ensure the `resource_indicator` matches before authorizing tool access.

- Discovery: Stytch serves both the OAuth 2.1 Authorization Server metadata (`/.well-known/oauth-authorization-server`) and the OIDC discovery document (`/.well-known/openid-configuration`). The strategy defaults to the OIDC endpoint so Assent can reach the `userinfo` endpoint automatically.

Example PRM payload your MCP server might expose:

```json
{
  "resource": "https://example.com/mcp",
  "authorization_servers": ["https://your-project.customers.stytch.com"],
  "scopes_supported": ["openid", "profile", "email"]
}
```

You can generate this payload directly from your strategy configuration using `AshAuthentication.Strategy.Stytch.PRM.build/3` and `json/2` and then serve it from a Plug or Phoenix route (for example, by mounting a `PRMPlug` at `/.well-known/oauth-protected-resource`):

```elixir
resource = "https://example.com/mcp"
issuer = "https://your-project.customers.stytch.com"
scopes = ["openid", "profile", "email", "mcp:tools:read"]

metadata = AshAuthentication.Strategy.Stytch.PRM.build(resource, [issuer], scopes: scopes)
File.write!("priv/static/.well-known/oauth-protected-resource", AshAuthentication.Strategy.Stytch.PRM.json(metadata))
```

For the latest MCP-related guidance, see Stytch’s Connected Apps documentation and the MCP specification.
