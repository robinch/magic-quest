defmodule Mix.Tasks.Cards.Import do
  @moduledoc "Downloads and imports MTG card data from MTGJSON"
  use Mix.Task

  @url "https://mtgjson.com/api/v5/AtomicCards.json.gz"

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("app.start")

    Mix.shell().info("Downloading AtomicCards.json.gz from MTGJSON...")

    tmp_gz = Path.join(System.tmp_dir!(), "atomic_cards.json.gz")
    tmp_json = Path.join(System.tmp_dir!(), "atomic_cards.json")

    case Req.get(@url, into: File.stream!(tmp_gz)) do
      {:ok, %{status: 200}} ->
        Mix.shell().info("Download complete. Decompressing...")

        # Decompress gzip
        gz_data = File.read!(tmp_gz)
        json_data = :zlib.gunzip(gz_data)
        File.write!(tmp_json, json_data)
        File.rm(tmp_gz)

        Mix.shell().info("Importing cards...")

        {:ok, count} = MagicQuest.Cards.Importer.import_from_file(tmp_json)
        Mix.shell().info("Successfully imported #{count} cards.")

        File.rm(tmp_json)

      {:ok, %{status: status}} ->
        Mix.shell().error("Download failed with status #{status}")

      {:error, reason} ->
        Mix.shell().error("Download failed: #{inspect(reason)}")
    end
  end
end
