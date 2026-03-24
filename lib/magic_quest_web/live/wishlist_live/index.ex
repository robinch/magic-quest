defmodule MagicQuestWeb.WishlistLive.Index do
  use MagicQuestWeb, :live_view

  alias MagicQuest.Wishlists
  alias MagicQuest.Cards
  alias MagicQuest.Scryfall
  alias MagicQuest.Workers.SearchCardWorker

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user

    if connected?(socket) do
      Phoenix.PubSub.subscribe(MagicQuest.PubSub, "user:#{user.id}:search")
    end

    cards = Wishlists.list_cards(user)

    {:ok,
     socket
     |> assign(:cards, cards)
     |> assign(:suggestions, [])
     |> assign(:search_query, "")
     |> assign(:expanded_card_id, nil)
     |> assign(:focused_card, nil)
     |> assign(:page_title, "My Wishlist")}
  end

  @impl true
  def handle_event("search_cards", %{"value" => query}, socket) do
    suggestions =
      query
      |> Cards.autocomplete()
      |> Enum.map(& &1.name)

    {:noreply, assign(socket, suggestions: suggestions, search_query: query)}
  end

  @impl true
  def handle_event("select_suggestion", %{"name" => name}, socket) do
    {:noreply, assign(socket, search_query: name, suggestions: [])}
  end

  @impl true
  def handle_event("add_card", %{"card_name" => card_name}, socket) do
    user = socket.assigns.current_scope.user
    card_name = String.trim(card_name)

    if card_name == "" do
      {:noreply, put_flash(socket, :error, "Card name cannot be empty")}
    else
      # Fetch card info from Scryfall for the image
      scryfall_attrs =
        case Scryfall.get_card(card_name) do
          {:ok, data} -> %{scryfall_id: data.scryfall_id, image_url: data.image_url}
          {:error, _} -> %{}
        end

      attrs = Map.merge(%{card_name: card_name}, scryfall_attrs)

      case Wishlists.add_card(user, attrs) do
        {:ok, card} ->
          # Enqueue alphaspel search
          %{wishlist_card_id: card.id}
          |> SearchCardWorker.new()
          |> Oban.insert()

          cards = Wishlists.list_cards(user)

          {:noreply,
           socket
           |> assign(:cards, cards)
           |> assign(:search_query, "")
           |> assign(:suggestions, [])
           |> put_flash(:info, "Added #{card_name} to wishlist")}

        {:error, changeset} ->
          message =
            case changeset.errors[:card_name] do
              {"has already been taken", _} -> "#{card_name} is already in your wishlist"
              _ -> "Could not add card"
            end

          {:noreply, put_flash(socket, :error, message)}
      end
    end
  end

  @impl true
  def handle_event("remove_card", %{"id" => id}, socket) do
    user = socket.assigns.current_scope.user
    card = Wishlists.get_card!(id)

    if card.user_id == user.id do
      {:ok, _} = Wishlists.remove_card(card)
      cards = Wishlists.list_cards(user)
      {:noreply, assign(socket, :cards, cards)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("search_now", %{"id" => id}, socket) do
    card = Wishlists.get_card!(id)

    if card.user_id == socket.assigns.current_scope.user.id do
      %{wishlist_card_id: card.id}
      |> SearchCardWorker.new()
      |> Oban.insert()

      {:noreply, put_flash(socket, :info, "Searching for #{card.card_name}...")}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("refresh_all", _params, socket) do
    socket.assigns.cards
    |> Enum.with_index()
    |> Enum.each(fn {card, index} ->
      %{wishlist_card_id: card.id}
      |> SearchCardWorker.new(scheduled_at: DateTime.add(DateTime.utc_now(), index * 5, :second))
      |> Oban.insert()
    end)

    {:noreply, put_flash(socket, :info, "Refreshing all cards...")}
  end

  @impl true
  def handle_event("toggle_expand", %{"id" => id}, socket) do
    id = String.to_integer(id)

    expanded =
      if socket.assigns.expanded_card_id == id, do: nil, else: id

    {:noreply, assign(socket, :expanded_card_id, expanded)}
  end

  @impl true
  def handle_event("show_image", %{"id" => id}, socket) do
    card = Enum.find(socket.assigns.cards, &(&1.id == String.to_integer(id)))
    {:noreply, assign(socket, :focused_card, card)}
  end

  @impl true
  def handle_event("close_image", _params, socket) do
    {:noreply, assign(socket, :focused_card, nil)}
  end

  @impl true
  def handle_info({:search_complete, card_id}, socket) do
    user = socket.assigns.current_scope.user
    cards = Wishlists.list_cards(user)

    card = Enum.find(cards, &(&1.id == card_id))
    in_stock_count = if card, do: Enum.count(card.listings, & &1.in_stock), else: 0

    socket =
      if card && in_stock_count > 0 do
        put_flash(socket, :info, "Found #{in_stock_count} listing(s) for #{card.card_name}!")
      else
        socket
      end

    {:noreply, assign(socket, :cards, cards)}
  end

  defp has_in_stock?(card) do
    Enum.any?(card.listings, & &1.in_stock)
  end

  defp in_stock_count(card) do
    Enum.count(card.listings, & &1.in_stock)
  end

  defp best_price(card) do
    card.listings
    |> Enum.filter(& &1.in_stock)
    |> Enum.map(& &1.price_kr)
    |> Enum.reject(&is_nil/1)
    |> Enum.min(fn -> nil end)
  end

  defp condition_label("begagnad"), do: "Used"
  defp condition_label("foil"), do: "Foil"
  defp condition_label("foil_begagnad"), do: "Foil (Used)"
  defp condition_label(_), do: "NM"
end
