defmodule MagicQuest.Decks do
  import Ecto.Query
  alias MagicQuest.Repo
  alias MagicQuest.Decks.{Deck, DeckCard}

  def list_decks(user) do
    Deck
    |> where(user_id: ^user.id)
    |> order_by(:name)
    |> preload(deck_cards: [wishlist_card: :listings])
    |> Repo.all()
  end

  def get_deck!(id) do
    Deck
    |> preload(deck_cards: [wishlist_card: :listings])
    |> Repo.get!(id)
  end

  def create_deck(user, attrs) do
    %Deck{user_id: user.id}
    |> Deck.changeset(attrs)
    |> Repo.insert()
  end

  def update_deck(%Deck{} = deck, attrs) do
    deck
    |> Deck.changeset(attrs)
    |> Repo.update()
  end

  def delete_deck(%Deck{} = deck) do
    Repo.delete(deck)
  end

  def change_deck(%Deck{} = deck, attrs \\ %{}) do
    Deck.changeset(deck, attrs)
  end

  def add_card_to_deck(deck_id, wishlist_card_id, priority \\ "nice_to_have") do
    %DeckCard{}
    |> DeckCard.changeset(%{deck_id: deck_id, wishlist_card_id: wishlist_card_id, priority: priority})
    |> Repo.insert()
  end

  def remove_card_from_deck(deck_id, wishlist_card_id) do
    DeckCard
    |> where(deck_id: ^deck_id, wishlist_card_id: ^wishlist_card_id)
    |> Repo.delete_all()
  end

  def toggle_priority(deck_id, wishlist_card_id) do
    deck_card =
      DeckCard
      |> where(deck_id: ^deck_id, wishlist_card_id: ^wishlist_card_id)
      |> Repo.one!()

    new_priority = if deck_card.priority == "must_have", do: "nice_to_have", else: "must_have"

    deck_card
    |> DeckCard.changeset(%{priority: new_priority})
    |> Repo.update()
  end

  def deck_stats(deck) do
    cards = deck.deck_cards

    total = length(cards)

    available =
      Enum.count(cards, fn dc ->
        Enum.any?(dc.wishlist_card.listings, & &1.in_stock)
      end)

    estimated_cost =
      cards
      |> Enum.map(fn dc ->
        dc.wishlist_card.listings
        |> Enum.filter(& &1.in_stock)
        |> Enum.map(& &1.price_kr)
        |> Enum.reject(&is_nil/1)
        |> Enum.min(fn -> 0 end)
      end)
      |> Enum.sum()

    %{total: total, available: available, estimated_cost: estimated_cost}
  end
end
