defmodule MagicQuest.Workers.RefreshAllWorker do
  use Oban.Worker, queue: :default

  import Ecto.Query
  alias MagicQuest.Repo
  alias MagicQuest.Wishlists.WishlistCard
  alias MagicQuest.Workers.SearchCardWorker

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    card_ids =
      WishlistCard
      |> select([c], c.id)
      |> Repo.all()

    card_ids
    |> Enum.with_index()
    |> Enum.each(fn {card_id, index} ->
      SearchCardWorker.new(
        %{wishlist_card_id: card_id},
        scheduled_at: DateTime.add(DateTime.utc_now(), index * 5, :second)
      )
      |> Oban.insert()
    end)

    :ok
  end
end
