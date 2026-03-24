defmodule MagicQuest.Repo.Migrations.CreateCards do
  use Ecto.Migration

  def change do
    create table(:cards) do
      add :name, :string, null: false
      add :colors, :string
      add :mana_cost, :string
      add :mana_value, :float
      add :type_line, :string
      add :text, :text

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:cards, [:name])
  end
end
