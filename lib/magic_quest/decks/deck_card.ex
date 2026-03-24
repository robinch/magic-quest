defmodule MagicQuest.Decks.DeckCard do
  use Ecto.Schema
  import Ecto.Changeset

  @priorities ~w(must_have nice_to_have)

  schema "deck_cards" do
    field :priority, :string, default: "nice_to_have"

    belongs_to :deck, MagicQuest.Decks.Deck
    belongs_to :wishlist_card, MagicQuest.Wishlists.WishlistCard

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(deck_card, attrs) do
    deck_card
    |> cast(attrs, [:priority, :deck_id, :wishlist_card_id])
    |> validate_required([:deck_id, :wishlist_card_id])
    |> validate_inclusion(:priority, @priorities)
    |> unique_constraint([:deck_id, :wishlist_card_id])
  end

  def priorities, do: @priorities
end
