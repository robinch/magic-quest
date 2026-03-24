defmodule MagicQuest.Wishlists do
  import Ecto.Query
  alias MagicQuest.Repo
  alias MagicQuest.Wishlists.{WishlistCard, Listing}

  def list_cards(user) do
    WishlistCard
    |> where(user_id: ^user.id)
    |> order_by(:card_name)
    |> preload(:listings)
    |> Repo.all()
  end

  def get_card!(id) do
    WishlistCard
    |> preload(:listings)
    |> Repo.get!(id)
  end

  def add_card(user, attrs) do
    %WishlistCard{user_id: user.id}
    |> WishlistCard.changeset(attrs)
    |> Repo.insert()
  end

  def update_card(%WishlistCard{} = card, attrs) do
    card
    |> WishlistCard.changeset(attrs)
    |> Repo.update()
  end

  def remove_card(%WishlistCard{} = card) do
    Repo.delete(card)
  end

  def replace_listings(%WishlistCard{} = card, listing_attrs) when is_list(listing_attrs) do
    now = DateTime.utc_now()

    Repo.transaction(fn ->
      Listing
      |> where(wishlist_card_id: ^card.id)
      |> Repo.delete_all()

      listings =
        Enum.map(listing_attrs, fn attrs ->
          %Listing{wishlist_card_id: card.id}
          |> Listing.changeset(Map.put(attrs, :last_checked_at, now))
          |> Repo.insert!()
        end)

      listings
    end)
  end

  def available_cards(user) do
    WishlistCard
    |> where(user_id: ^user.id)
    |> join(:inner, [wc], l in Listing, on: l.wishlist_card_id == wc.id and l.in_stock == true)
    |> distinct(true)
    |> preload(:listings)
    |> Repo.all()
  end
end
