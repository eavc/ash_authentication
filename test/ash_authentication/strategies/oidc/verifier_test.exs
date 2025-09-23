defmodule AshAuthentication.Strategy.Oidc.VerifierTest do
  @moduledoc false
  use ExUnit.Case, async: true

  defmodule TestDomain do
    @moduledoc false
    use Ash.Domain, validate_config_inclusion?: false

    resources do
      allow_unregistered? true
    end
  end

  test "requires private_key when client_authentication_method is private_key_jwt" do
    assert_raise Spark.Error.DslError, ~r/private_key/i, fn ->
      defmodule TestUserOidcPrivateKeyMissing do
        @moduledoc false
        use Ash.Resource,
          data_layer: Ash.DataLayer.Ets,
          extensions: [AshAuthentication],
          domain: AshAuthentication.Strategy.Oidc.VerifierTest.TestDomain

        attributes do
          uuid_primary_key :id
        end

        identities do
          identity :unique_id, [:id], pre_check?: true
        end

        authentication do
          strategies do
            oidc do
              client_id &__MODULE__.secret/2
              base_url &__MODULE__.secret/2
              redirect_uri &__MODULE__.secret/2
              client_authentication_method "private_key_jwt"
              # intentionally omit :private_key
            end
          end
        end

        actions do
          read :read do
            primary? true
          end

          create :register_with_oidc do
            argument :user_info, :map, allow_nil?: false
            argument :oauth_tokens, :map, allow_nil?: false
            upsert? true
            upsert_identity :unique_id
          end
        end

        def secret(_path, _resource), do: {:ok, "https://example.com"}
      end
    end
  end

  test "compiles when private_key is provided for private_key_jwt" do
    defmodule TestUserOidcWithPrivateKey do
      @moduledoc false
      use Ash.Resource,
        data_layer: Ash.DataLayer.Ets,
        extensions: [AshAuthentication],
        domain: AshAuthentication.Strategy.Oidc.VerifierTest.TestDomain

      attributes do
        uuid_primary_key :id
      end

      identities do
        identity :unique_id, [:id], pre_check?: true
      end

      authentication do
        strategies do
          oidc do
            client_id &__MODULE__.secret/2
            base_url &__MODULE__.secret/2
            redirect_uri &__MODULE__.secret/2
            client_authentication_method "private_key_jwt"
            private_key &__MODULE__.secret/2
          end
        end
      end

      actions do
        read :read do
          primary? true
        end

        create :register_with_oidc do
          argument :user_info, :map, allow_nil?: false
          argument :oauth_tokens, :map, allow_nil?: false
          upsert? true
          upsert_identity :unique_id
        end
      end

      def secret(_path, _resource), do: {:ok, "https://example.com"}
    end

    # If we reach here, compilation succeeded and verifier accepted configuration
    assert true
  end
end
