defmodule MagicQuest.Alphaspel do
  @base_url "https://alphaspel.se"
  @search_path "/947-kortspel/search/"

  def search(card_name) when is_binary(card_name) do
    with {:ok, html} <- fetch_page(@search_path, query: card_name) do
      results = parse_results(html)
      total_pages = parse_pagination(html)

      # Follow pagination with rate limiting
      additional_results =
        if total_pages > 1 do
          Enum.flat_map(2..total_pages//1, fn page ->
            Process.sleep(2_000)

            case fetch_page(@search_path, query: card_name, page: page) do
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
    |> Floki.find("div.product")
    |> Enum.map(&parse_product/1)
    |> Enum.reject(&is_nil/1)
  end

  def parse_pagination(html) when is_binary(html) do
    {:ok, doc} = Floki.parse_document(html)

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

  defp parse_product(product_div) do
    # Extract link and name
    link = Floki.find(product_div, "a") |> List.first()
    if is_nil(link), do: throw(:skip)

    href = Floki.attribute(link, "href") |> List.first("")
    product_name_text = Floki.find(product_div, ".product-name") |> Floki.text() |> String.trim()

    # Extract price
    price_text = Floki.find(product_div, ".price") |> Floki.text() |> String.trim()

    price_kr =
      case Regex.run(~r/(\d+)\s*kr/, price_text) do
        [_, price] -> String.to_integer(price)
        nil -> nil
      end

    # Extract stock
    stock_text = Floki.find(product_div, ".stock") |> Floki.text() |> String.trim()

    {stock, in_stock} =
      cond do
        match = Regex.run(~r/(\d+)\s*i butiken/, stock_text) ->
          {String.to_integer(Enum.at(match, 1)), true}

        String.contains?(stock_text, "Slutsåld") ->
          {0, false}

        true ->
          {0, false}
      end

    # Parse name, set, condition
    {name, set_name, condition} = parse_product_name(product_name_text)

    if name != "" do
      %{
        name: name,
        set_name: set_name,
        price_kr: price_kr,
        stock: stock,
        in_stock: in_stock,
        condition: condition,
        url: @base_url <> href
      }
    end
  catch
    :skip -> nil
  end

  defp parse_product_name(text) do
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

    # Format: "Magic löskort: Set Name: Card Name"
    # Strip "Magic löskort: " prefix first, then split set from card on last ": "
    stripped =
      clean_text
      |> String.replace(~r/^Magic löskort:\s*/i, "")
      |> String.trim()

    # Split on last ": " to separate "Set Name" from "Card Name"
    case String.split(stripped, ": ") do
      parts when length(parts) >= 2 ->
        card_name = List.last(parts)
        set_name = parts |> Enum.drop(-1) |> Enum.join(": ")
        {String.trim(card_name), String.trim(set_name), condition}

      [only] ->
        {String.trim(only), nil, condition}
    end
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
