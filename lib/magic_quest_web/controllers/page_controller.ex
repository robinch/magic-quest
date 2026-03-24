defmodule MagicQuestWeb.PageController do
  use MagicQuestWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
