defmodule MagicQuest.Repo.Migrations.CreateListings do
  use Ecto.Migration

  def change do
    create table(:listings) do
      add :name, :string, null: false
      add :set_name, :string
      add :price_kr, :integer
      add :stock, :integer, default: 0
      add :in_stock, :boolean, default: false
      add :condition, :string
      add :url, :string
      add :last_checked_at, :utc_datetime_usec
      add :wishlist_card_id, references(:wishlist_cards, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:listings, [:wishlist_card_id])
  end
end
