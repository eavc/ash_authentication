defmodule AshAuthentication.Strategy.Stytch.StrategyTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias AshAuthentication.{Info, Strategy, Strategy.OAuth2}
  alias AshAuthentication.Strategy.OAuth2.Plug, as: OAuth2Plug
  alias AshAuthentication.Strategy.Stytch.HttpAdapter, as: StytchHttpAdapter
  alias Assent.HTTPAdapter.HTTPResponse

  use Mimic
  import Plug.Test

  defmodule StubAdapter do
    @moduledoc false
    @behaviour Assent.HTTPAdapter

    @impl Assent.HTTPAdapter
    def request(method, url, body, headers, opts) do
      send(self(), {:adapter_request, method, url, body, headers, opts})
      {:ok, %HTTPResponse{status: 200, headers: [], body: %{}}}
    end
  end

  describe "Info.strategy/2" do
    test "returns an OIDC-backed strategy tagged for Stytch" do
      assert {:ok, %OAuth2{} = strategy} = Info.strategy(Example.User, :stytch)

      assert strategy.provider == :stytch
      assert strategy.icon == :stytch
      assert strategy.assent_strategy == Assent.Strategy.OIDC
      assert strategy.openid_configuration_uri == "/.well-known/openid-configuration"
    end
  end

  describe "Strategy.routes/1" do
    test "uses the stytch path prefix" do
      {:ok, strategy} = Info.strategy(Example.User, :stytch)

      routes =
        strategy
        |> Strategy.routes()
        |> MapSet.new()

      assert MapSet.member?(routes, {"/user/stytch", :request})
      assert MapSet.member?(routes, {"/user/stytch/callback", :callback})
    end
  end

  describe "Strategy.phases/1" do
    test "mirrors the underlying OIDC phases" do
      {:ok, strategy} = Info.strategy(Example.User, :stytch)

      phases =
        strategy
        |> Strategy.phases()
        |> MapSet.new()

      assert phases == MapSet.new(~w[request callback]a)
    end
  end

  describe "resource indicator handling" do
    setup do
      Mimic.copy(Assent.Strategy.OIDC)
      :ok
    end

    test "is injected into the authorization request" do
      {:ok, strategy} = Info.strategy(Example.User, :stytch)

      conn =
        :get
        |> conn("/")
        |> init_test_session(%{})

      Assent.Strategy.OIDC
      |> expect(:authorize_url, fn config ->
        params = Keyword.fetch!(config, :authorization_params)
        assert Keyword.get(params, :resource) == "https://example.com/mcp"

        audiences = Keyword.fetch!(config, :trusted_audiences)
        assert "https://example.com/mcp" in audiences

        {:ok, %{url: "https://stytch.example.com/oauth/authorize", session_params: %{}}}
      end)

      _ = OAuth2Plug.request(conn, strategy)
    end

    test "http adapter adds the resource when exchanging codes" do
      opts = [adapter: {StubAdapter, []}, resource_indicator: "https://example.com/mcp"]
      body = URI.encode_query(%{"grant_type" => "authorization_code", "code" => "abc"})

      assert {:ok, %HTTPResponse{}} =
               StytchHttpAdapter.request(
                 :post,
                 "https://stytch.example.com/token",
                 body,
                 [],
                 opts
               )

      assert_receive {:adapter_request, :post, _, injected_body, _headers, []}

      params = URI.decode_query(IO.iodata_to_binary(injected_body))

      assert params["resource"] == "https://example.com/mcp"
      assert params["grant_type"] == "authorization_code"
    end
  end
end
