defmodule MagicQuest.Alphaspel do
  @base_url "https://alphaspel.se"
  @search_path "/1978-mtg-loskort/"

  def search(card_name) when is_binary(card_name) do
    with {:ok, html} <- fetch_page(@search_path, q: card_name) do
      results = parse_results(html)
      total_pages = parse_pagination(html)

      # Follow pagination with rate limiting
      additional_results =
        if total_pages > 1 do
          Enum.flat_map(2..total_pages//1, fn page ->
            Process.sleep(2_000)

            case fetch_page(@search_path, q: card_name, page: page) do
              {:ok, page_html} -> parse_results(page_html)
              {:error, _} -> []
            end
          end)
        else
          []
        end

      {:ok, results ++ additional_results}
    end
  end

  def fetch_page(path, params) do
    case Req.get(client(), url: path, params: params) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %{status: status}} ->
        {:error, {:http_error, status}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def parse_results(html) when is_binary(html) do
    {:ok, doc} = Floki.parse_document(html)

    doc
    |> Floki.find("a[href*='magic-loskort']")
    |> Enum.map(&parse_card_element/1)
    |> Enum.reject(&is_nil/1)
  end

  def parse_pagination(html) when is_binary(html) do
    {:ok, doc} = Floki.parse_document(html)

    # Look for pagination links — the last numbered page link
    page_links =
      doc
      |> Floki.find("a[href*='page=']")
      |> Enum.flat_map(fn element ->
        text = Floki.text(element) |> String.trim()

        case Integer.parse(text) do
          {num, ""} -> [num]
          _ -> []
        end
      end)

    case page_links do
      [] -> 1
      pages -> Enum.max(pages)
    end
  end

  defp parse_card_element(element) do
    text = Floki.text(element) |> String.trim()
    href = Floki.attribute(element, "href") |> List.first("")

    # Extract image URL
    image_url =
      element
      |> Floki.find("img")
      |> Floki.attribute("src")
      |> List.first()

    # Parse the product name and extract card details
    {name, set_name, condition} = parse_product_name(text)
    {price_kr, stock, in_stock} = parse_price_and_stock(text)

    if name != "" do
      %{
        name: name,
        set_name: set_name,
        price_kr: price_kr,
        stock: stock,
        in_stock: in_stock,
        condition: condition,
        url: @base_url <> href,
        image_url: if(image_url, do: @base_url <> image_url)
      }
    end
  end

  defp parse_product_name(text) do
    # Format: "Magic löskort: Set Name: Card Name (Begagnad)"
    condition =
      cond do
        String.contains?(text, "(Begagnad)") and String.contains?(text, "(Foil)") ->
          "foil_begagnad"

        String.contains?(text, "(Begagnad)") ->
          "begagnad"

        String.contains?(text, "(Foil)") ->
          "foil"

        true ->
          "normal"
      end

    clean_text =
      text
      |> String.replace(~r/\(Begagnad\)|\(Foil\)/, "")
      |> String.trim()

    case String.split(clean_text, ":", parts: 3) do
      [_prefix, set_name, card_name] ->
        {String.trim(card_name), String.trim(set_name), condition}

      [_prefix, card_name] ->
        {String.trim(card_name), nil, condition}

      _ ->
        {clean_text, nil, condition}
    end
  end

  defp parse_price_and_stock(text) do
    price_kr =
      case Regex.run(~r/(\d+)\s*kr/, text) do
        [_, price] -> String.to_integer(price)
        nil -> nil
      end

    {stock, in_stock} =
      cond do
        match = Regex.run(~r/(\d+)\s*i butiken/, text) ->
          {String.to_integer(Enum.at(match, 1)), true}

        String.contains?(text, "Slutsåld") ->
          {0, false}

        true ->
          {0, false}
      end

    {price_kr, stock, in_stock}
  end

  defp client do
    opts = [
      base_url: @base_url,
      headers: [{"user-agent", "MagicQuest/1.0 (personal wishlist tracker)"}],
      redirect: true
    ]

    opts =
      if plug = Application.get_env(:magic_quest, :alphaspel_plug) do
        Keyword.put(opts, :plug, plug)
      else
        opts
      end

    Req.new(opts)
  end
end
