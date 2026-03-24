defmodule MagicQuest.Workers.SearchCardWorker do
  use Oban.Worker, queue: :search, unique: [period: 60]

  alias MagicQuest.{Wishlists, Alphaspel}

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"wishlist_card_id" => card_id}}) do
    card = Wishlists.get_card!(card_id)

    case Alphaspel.search(card.card_name) do
      {:ok, results} ->
        Wishlists.replace_listings(card, results)

        Phoenix.PubSub.broadcast(
          MagicQuest.PubSub,
          "user:#{card.user_id}:search",
          {:search_complete, card_id}
        )

        :ok

      {:error, reason} ->
        {:error, reason}
    end
  end
end
