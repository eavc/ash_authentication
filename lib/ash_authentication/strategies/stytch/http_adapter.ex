defmodule AshAuthentication.Strategy.Stytch.HttpAdapter do
  @moduledoc """
  HTTP adapter wrapper that injects the RFC 8707 resource indicator into token requests.

  Wraps another `Assent.HTTPAdapter` implementation and adds the `resource`
  parameter when exchanging authorization codes (or other grant types) for
  access tokens. This keeps the behaviour isolated to the Stytch strategy
  without patching upstream Assent modules.
  """

  alias Assent.HTTPAdapter

  @behaviour HTTPAdapter

  @impl HTTPAdapter
  def request(method, url, body, headers, opts) do
    {adapter, adapter_opts} = Keyword.fetch!(opts, :adapter)
    resource_indicator = Keyword.get(opts, :resource_indicator)

    {method, body} = maybe_inject_resource(method, body, resource_indicator)

    adapter.request(method, url, body, headers, adapter_opts)
  end

  defp maybe_inject_resource(:post, body, resource) when is_binary(resource) and resource != "" do
    form =
      body
      |> IO.iodata_to_binary()
      |> decode_query()

    case Map.has_key?(form, "resource") do
      true ->
        {:post, body}

      false ->
        form
        |> Map.put("resource", resource)
        |> encode_query()
        |> then(&{:post, &1})
    end
  end

  defp maybe_inject_resource(method, body, _resource), do: {method, body}

  defp decode_query(""), do: %{}
  defp decode_query(body), do: URI.decode_query(body)

  defp encode_query(map) when is_map(map), do: URI.encode_query(map)
end
