defmodule MagicQuest.Wishlists.Listing do
  use Ecto.Schema
  import Ecto.Changeset

  schema "listings" do
    field :name, :string
    field :set_name, :string
    field :price_kr, :integer
    field :stock, :integer, default: 0
    field :in_stock, :boolean, default: false
    field :condition, :string
    field :url, :string
    field :last_checked_at, :utc_datetime_usec

    belongs_to :wishlist_card, MagicQuest.Wishlists.WishlistCard

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(listing, attrs) do
    listing
    |> cast(attrs, [:name, :set_name, :price_kr, :stock, :in_stock, :condition, :url, :last_checked_at])
    |> validate_required([:name])
  end
end
