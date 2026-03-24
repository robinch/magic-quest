defmodule MagicQuest.Cards.Importer do
  alias MagicQuest.Repo
  alias MagicQuest.Cards.Card

  @chunk_size 1000

  def import_from_file(path) do
    data =
      path
      |> File.read!()
      |> Jason.decode!()
      |> Map.get("data", %{})

    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

    cards =
      data
      |> Enum.map(fn {name, card_data} ->
        # card_data is a list of printings — take the first for metadata
        first = List.first(card_data) || %{}

        %{
          name: name,
          colors: (first["colors"] || []) |> Enum.join(","),
          mana_cost: first["manaCost"],
          mana_value: first["manaValue"],
          type_line: first["type"],
          text: first["text"],
          inserted_at: now,
          updated_at: now
        }
      end)

    total =
      cards
      |> Enum.chunk_every(@chunk_size)
      |> Enum.reduce(0, fn chunk, acc ->
        {count, _} =
          Repo.insert_all(Card, chunk,
            on_conflict: {:replace_all_except, [:id, :inserted_at]},
            conflict_target: :name
          )

        acc + count
      end)

    {:ok, total}
  end
end
