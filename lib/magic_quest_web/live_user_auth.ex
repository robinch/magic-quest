defmodule MagicQuestWeb.LiveUserAuth do
  @moduledoc """
  LiveView on_mount hooks for user authentication.
  """
  import Phoenix.Component

  alias MagicQuest.Accounts
  alias MagicQuest.Accounts.Scope

  def on_mount(:ensure_authenticated, _params, session, socket) do
    socket = mount_current_scope(socket, session)

    if socket.assigns.current_scope && socket.assigns.current_scope.user do
      {:cont, socket}
    else
      socket =
        socket
        |> Phoenix.LiveView.put_flash(:error, "You must log in to access this page.")
        |> Phoenix.LiveView.redirect(to: "/users/log-in")

      {:halt, socket}
    end
  end

  defp mount_current_scope(socket, session) do
    case session do
      %{"user_token" => user_token} ->
        case Accounts.get_user_by_session_token(user_token) do
          {user, _token_inserted_at} ->
            assign(socket, :current_scope, Scope.for_user(user))

          nil ->
            assign(socket, :current_scope, Scope.for_user(nil))
        end

      _ ->
        assign(socket, :current_scope, Scope.for_user(nil))
    end
  end
end
