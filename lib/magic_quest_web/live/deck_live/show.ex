defmodule MagicQuestWeb.DeckLive.Show do
  use MagicQuestWeb, :live_view

  alias MagicQuest.Decks
  alias MagicQuest.Wishlists

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    user = socket.assigns.current_scope.user
    deck = Decks.get_deck!(id)

    if deck.user_id != user.id do
      {:ok, push_navigate(socket, to: ~p"/decks")}
    else
      if connected?(socket) do
        Phoenix.PubSub.subscribe(MagicQuest.PubSub, "user:#{user.id}:search")
      end

      user_cards = Wishlists.list_cards(user)

      {:ok,
       socket
       |> assign(:deck, deck)
       |> assign(:user_cards, user_cards)
       |> assign(:show_add_card, false)
       |> assign(:page_title, deck.name)
       |> assign_sorted_cards()}
    end
  end

  @impl true
  def handle_event("add_card", %{"card_id" => card_id}, socket) do
    card_id = String.to_integer(card_id)

    case Decks.add_card_to_deck(socket.assigns.deck.id, card_id) do
      {:ok, _} ->
        {:noreply, reload_deck(socket) |> assign(:show_add_card, false)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Card already in deck")}
    end
  end

  @impl true
  def handle_event("remove_card", %{"card-id" => card_id}, socket) do
    Decks.remove_card_from_deck(socket.assigns.deck.id, String.to_integer(card_id))
    {:noreply, reload_deck(socket)}
  end

  @impl true
  def handle_event("toggle_priority", %{"card-id" => card_id}, socket) do
    Decks.toggle_priority(socket.assigns.deck.id, String.to_integer(card_id))
    {:noreply, reload_deck(socket)}
  end

  @impl true
  def handle_event("toggle_add_card", _params, socket) do
    {:noreply, assign(socket, :show_add_card, !socket.assigns.show_add_card)}
  end

  @impl true
  def handle_info({:search_complete, _card_id}, socket) do
    {:noreply, reload_deck(socket)}
  end

  defp reload_deck(socket) do
    deck = Decks.get_deck!(socket.assigns.deck.id)
    user_cards = Wishlists.list_cards(socket.assigns.current_scope.user)

    socket
    |> assign(:deck, deck)
    |> assign(:user_cards, user_cards)
    |> assign_sorted_cards()
  end

  defp assign_sorted_cards(socket) do
    sorted =
      socket.assigns.deck.deck_cards
      |> Enum.sort_by(fn dc ->
        {if(dc.priority == "must_have", do: 0, else: 1), dc.wishlist_card.card_name}
      end)

    assign(socket, :sorted_deck_cards, sorted)
  end

  defp cards_not_in_deck(user_cards, deck) do
    deck_card_ids = MapSet.new(deck.deck_cards, & &1.wishlist_card_id)
    Enum.reject(user_cards, fn c -> MapSet.member?(deck_card_ids, c.id) end)
  end

  defp best_price(wishlist_card) do
    wishlist_card.listings
    |> Enum.filter(& &1.in_stock)
    |> Enum.map(& &1.price_kr)
    |> Enum.reject(&is_nil/1)
    |> Enum.min(fn -> nil end)
  end

  defp has_in_stock?(wishlist_card) do
    Enum.any?(wishlist_card.listings, & &1.in_stock)
  end

  defp format_label(format) do
    format |> String.replace("_", " ") |> String.capitalize()
  end

  defp priority_label("must_have"), do: "Must have"
  defp priority_label(_), do: "Nice to have"
end
