defmodule MagicQuest.Wishlists.WishlistCard do
  use Ecto.Schema
  import Ecto.Changeset

  schema "wishlist_cards" do
    field :card_name, :string
    field :scryfall_id, :string
    field :image_url, :string
    field :max_price_kr, :integer
    field :notes, :string

    belongs_to :user, MagicQuest.Accounts.User
    has_many :listings, MagicQuest.Wishlists.Listing
    has_many :deck_cards, MagicQuest.Decks.DeckCard

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(wishlist_card, attrs) do
    wishlist_card
    |> cast(attrs, [:card_name, :scryfall_id, :image_url, :max_price_kr, :notes])
    |> validate_required([:card_name])
    |> unique_constraint([:user_id, :card_name])
  end
end
