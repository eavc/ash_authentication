defmodule AshAuthentication.Strategy.Stytch.StrategyTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias AshAuthentication.{Info, Strategy, Strategy.OAuth2}

  describe "Info.strategy/2" do
    test "returns an OIDC-backed strategy tagged for Stytch" do
      assert {:ok, %OAuth2{} = strategy} = Info.strategy(Example.User, :stytch)

      assert strategy.provider == :stytch
      assert strategy.icon == :stytch
      assert strategy.assent_strategy == Assent.Strategy.OIDC
      assert strategy.openid_configuration_uri == "/.well-known/oauth-authorization-server"
      assert strategy.authorization_params[:resource] == "https://example.com/mcp"
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
end
