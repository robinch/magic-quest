defmodule MagicQuest.Repo.Migrations.CreateWishlistCards do
  use Ecto.Migration

  def change do
    create table(:wishlist_cards) do
      add :card_name, :string, null: false
      add :scryfall_id, :string
      add :image_url, :string
      add :max_price_kr, :integer
      add :notes, :text
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:wishlist_cards, [:user_id])
    create unique_index(:wishlist_cards, [:user_id, :card_name])
  end
end
