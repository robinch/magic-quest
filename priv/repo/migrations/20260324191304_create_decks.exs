defmodule MagicQuest.Repo.Migrations.CreateDecks do
  use Ecto.Migration

  def change do
    create table(:decks) do
      add :name, :string, null: false
      add :format, :string, null: false, default: "other"
      add :description, :text
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:decks, [:user_id])
    create unique_index(:decks, [:user_id, :name])
  end
end
