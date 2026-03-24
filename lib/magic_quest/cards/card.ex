defmodule MagicQuest.Cards.Card do
  use Ecto.Schema
  import Ecto.Changeset

  schema "cards" do
    field :name, :string
    field :colors, :string
    field :mana_cost, :string
    field :mana_value, :float
    field :type_line, :string
    field :text, :string

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(card, attrs) do
    card
    |> cast(attrs, [:name, :colors, :mana_cost, :mana_value, :type_line, :text])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end
end
