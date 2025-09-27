defmodule AshAuthentication.Strategy.Stytch.Dsl do
  @moduledoc false

  alias AshAuthentication.Strategy.{Custom, Oidc}
  alias Spark.Dsl.Entity

  @doc false
  @spec dsl :: Custom.entity()
  def dsl do
    oidc = Oidc.Dsl.dsl()

    %Entity{
      oidc
      | name: :stytch,
        args: [{:optional, :name, :stytch}],
        describe: """
        Provides an authentication strategy preconfigured for Stytch Connected Apps acting as an OIDC provider.

        This strategy inherits all configuration from the `:oidc` strategy. Use it when your Stytch project issues tokens for your MCP server. Provide your project domain via `base_url` (for example, `https://your-project.customers.stytch.com`) or a custom domain and Stytch client credentials via secrets.

        Discovery note: Stytch publishes OAuth 2.1 Authorization Server metadata
        at `/.well-known/oauth-authorization-server`, rather than the OIDC provider
        discovery path `/.well-known/openid-configuration`. The required fields for
        this strategy (authorization, token, JWKS, issuer) are present in Stytch's
        Authorization Server metadata, so the Stytch strategy defaults to that path
        on purpose.

        #### More documentation:
        - The [Stytch Tutorial](/documentation/tutorials/stytch.md).
        - The [OIDC documentation](`AshAuthentication.Strategy.Oidc`)
        """,
        auto_set_fields: build_auto_set_fields(oidc.auto_set_fields),
        schema: patch_schema(oidc.schema)
    }
  end

  defp build_auto_set_fields(auto_set_fields) do
    auto_set_fields
    |> Keyword.merge(provider: :stytch, icon: :stytch)
  end

  defp patch_schema(schema) do
    schema
    |> update_option(:base_url, fn opts ->
      existing_doc = Keyword.get(opts, :doc, "")

      doc =
        [
          existing_doc,
          "For Stytch, set this to your project domain (eg `https://example.customers.stytch.com`) or to your configured custom domain."
        ]
        |> Enum.reject(&(&1 == ""))
        |> Enum.join(" ")

      Keyword.put(opts, :doc, doc)
    end)
    |> update_option(:authorization_params, fn opts ->
      existing_doc = Keyword.get(opts, :doc, "")

      doc =
        [
          existing_doc,
          "Scopes still belong here. When you also set `resource_indicator`, the strategy automatically adds the `resource` parameter for you."
        ]
        |> Enum.reject(&(&1 == ""))
        |> Enum.join(" ")

      Keyword.put(opts, :doc, doc)
    end)
    |> update_option(:openid_configuration_uri, fn opts ->
      existing_doc = Keyword.get(opts, :doc, "")

      doc =
        [
          existing_doc,
          "The relative path used to fetch Stytch's OAuth authorization server metadata. Defaults to `/.well-known/oauth-authorization-server`."
        ]
        |> Enum.reject(&(&1 == ""))
        |> Enum.join(" ")

      opts
      |> Keyword.put(:default, "/.well-known/oauth-authorization-server")
      |> Keyword.put(:doc, doc)
    end)
    |> update_option(:code_verifier, &Keyword.put(&1, :default, true))
    |> Keyword.put(:resource_indicator,
      type: AshAuthentication.Dsl.secret_type(),
      doc:
        "The RFC 8707 resource indicator to request tokens for (eg `https://example.com/mcp`). When set, the strategy automatically includes it in authorization and token requests. Make sure the same value appears in `trusted_audiences` so ID token audience validation succeeds.",
      required: false
    )
  end

  defp update_option(schema, key, func) do
    Keyword.update!(schema, key, func)
  end
end
