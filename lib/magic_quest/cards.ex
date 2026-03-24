defmodule MagicQuest.Cards do
  import Ecto.Query
  alias MagicQuest.Repo
  alias MagicQuest.Cards.Card

  def autocomplete(query, limit \\ 8) when is_binary(query) do
    if String.length(query) < 2 do
      []
    else
      sanitized = sanitize_like(query)
      prefix_pattern = "#{sanitized}%"
      contains_pattern = "%#{sanitized}%"

      # Prefix matches first, then contains matches, to prioritize exact starts
      Card
      |> where([c], ilike(c.name, ^contains_pattern))
      |> order_by([c], [
        asc: fragment("CASE WHEN ? ILIKE ? THEN 0 ELSE 1 END", c.name, ^prefix_pattern),
        asc: c.name
      ])
      |> limit(^limit)
      |> Repo.all()
    end
  end

  def get_by_name(name) when is_binary(name) do
    Repo.get_by(Card, name: name)
  end

  defp sanitize_like(query) do
    query
    |> String.replace("\\", "\\\\")
    |> String.replace("%", "\\%")
    |> String.replace("_", "\\_")
  end
end
