defmodule MagicQuest.Scryfall do
  @base_url "https://api.scryfall.com"

  def get_card(exact_name) when is_binary(exact_name) do
    case Req.get(client(), url: "/cards/named", params: [exact: exact_name]) do
      {:ok, %{status: 200, body: body}} ->
        {:ok,
         %{
           scryfall_id: body["id"],
           image_url: get_in(body, ["image_uris", "normal"]),
           name: body["name"]
         }}

      {:ok, %{status: status, body: body}} ->
        {:error, {status, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp client do
    opts = [
      base_url: @base_url,
      headers: [
        {"user-agent", "MagicQuest/1.0 (personal wishlist tracker)"},
        {"accept", "application/json"}
      ]
    ]

    opts =
      if plug = Application.get_env(:magic_quest, :scryfall_plug) do
        Keyword.put(opts, :plug, plug)
      else
        opts
      end

    Req.new(opts)
  end
end
