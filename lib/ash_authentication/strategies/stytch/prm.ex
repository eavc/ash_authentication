defmodule AshAuthentication.Strategy.Stytch.PRM do
  @moduledoc """
  Convenience helpers for generating Protected Resource Metadata (PRM) payloads
  required by MCP 2025-06-18.

  Use `build/3` to construct the metadata map and `json/2` to encode it for
  serving at `/.well-known/oauth-protected-resource`.
  """

  @type metadata :: map()

  @doc """
  Build a PRM document from the resource indicator, authorization servers and
  optional scopes / bearer methods.
  """
  @spec build(String.t(), [String.t()], keyword) :: metadata
  def build(resource, authorization_servers, opts \\ []) do
    scopes = Keyword.get(opts, :scopes, [])
    bearer_methods = Keyword.get(opts, :bearer_methods, ["bearer"])

    %{
      "resource" => resource,
      "authorization_servers" => authorization_servers
    }
    |> maybe_put("scopes_supported", scopes)
    |> maybe_put("bearer_methods_supported", bearer_methods)
  end

  @doc """
  Encode metadata as JSON for serving via Plug or static file.
  """
  @spec json(metadata, keyword) :: String.t()
  def json(metadata, opts \\ []) do
    encoder = Keyword.get(opts, :encoder, Jason)

    encoder.encode!(metadata)
  end

  defp maybe_put(map, _key, []), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
