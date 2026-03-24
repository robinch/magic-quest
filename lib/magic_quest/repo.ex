defmodule MagicQuest.Repo do
  use Ecto.Repo,
    otp_app: :magic_quest,
    adapter: Ecto.Adapters.Postgres
end
