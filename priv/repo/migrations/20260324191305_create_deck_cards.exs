defmodule MagicQuest.Repo.Migrations.CreateDeckCards do
  use Ecto.Migration

  def change do
    create table(:deck_cards) do
      add :priority, :string, null: false, default: "nice_to_have"
      add :deck_id, references(:decks, on_delete: :delete_all), null: false
      add :wishlist_card_id, references(:wishlist_cards, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:deck_cards, [:deck_id])
    create index(:deck_cards, [:wishlist_card_id])
    create unique_index(:deck_cards, [:deck_id, :wishlist_card_id])
  end
end
