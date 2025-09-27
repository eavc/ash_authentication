defmodule AshAuthentication.Strategy.Stytch.PRMTest do
  use ExUnit.Case, async: true

  alias AshAuthentication.Strategy.Stytch.PRM

  test "build/3 populates defaults" do
    metadata = PRM.build("https://example.com/mcp", ["https://issuer"], scopes: ["openid"])

    assert metadata["resource"] == "https://example.com/mcp"
    assert metadata["authorization_servers"] == ["https://issuer"]
    assert metadata["scopes_supported"] == ["openid"]
    assert metadata["bearer_methods_supported"] == ["bearer"]
  end

  test "json/2 uses provided encoder" do
    metadata = %{"resource" => "r", "authorization_servers" => ["a"]}
    assert metadata == Jason.decode!(PRM.json(metadata))
  end
end
