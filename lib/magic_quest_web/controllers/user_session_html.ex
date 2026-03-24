defmodule MagicQuestWeb.UserSessionHTML do
  use MagicQuestWeb, :html

  embed_templates "user_session_html/*"

  defp local_mail_adapter? do
    Application.get_env(:magic_quest, MagicQuest.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end
