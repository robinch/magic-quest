defmodule MagicQuest.Decks.Deck do
  use Ecto.Schema
  import Ecto.Changeset

  @formats ~w(commander standard modern pioneer pauper legacy vintage other)

  schema "decks" do
    field :name, :string
    field :format, :string, default: "other"
    field :description, :string

    belongs_to :user, MagicQuest.Accounts.User
    has_many :deck_cards, MagicQuest.Decks.DeckCard
    many_to_many :wishlist_cards, MagicQuest.Wishlists.WishlistCard, join_through: MagicQuest.Decks.DeckCard

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(deck, attrs) do
    deck
    |> cast(attrs, [:name, :format, :description])
    |> validate_required([:name, :format])
    |> validate_inclusion(:format, @formats)
    |> unique_constraint([:user_id, :name])
  end

  def formats, do: @formats
end
