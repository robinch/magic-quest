defmodule MagicQuestWeb.DeckLive.Index do
  use MagicQuestWeb, :live_view

  alias MagicQuest.Decks
  alias MagicQuest.Decks.Deck

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    decks = Decks.list_decks(user)

    {:ok,
     socket
     |> assign(:decks, decks)
     |> assign(:page_title, "My Decks")}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Deck")
    |> assign(:deck, %Deck{})
    |> assign(:changeset, Decks.change_deck(%Deck{}))
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    deck = Decks.get_deck!(id)
    user = socket.assigns.current_scope.user

    if deck.user_id == user.id do
      socket
      |> assign(:page_title, "Edit #{deck.name}")
      |> assign(:deck, deck)
      |> assign(:changeset, Decks.change_deck(deck))
    else
      push_navigate(socket, to: ~p"/decks")
    end
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:deck, nil)
    |> assign(:changeset, nil)
  end

  @impl true
  def handle_event("save", %{"deck" => deck_params}, socket) do
    user = socket.assigns.current_scope.user

    result =
      if socket.assigns.deck.id do
        Decks.update_deck(socket.assigns.deck, deck_params)
      else
        Decks.create_deck(user, deck_params)
      end

    case result do
      {:ok, _deck} ->
        decks = Decks.list_decks(user)

        {:noreply,
         socket
         |> assign(:decks, decks)
         |> put_flash(:info, "Deck saved")
         |> push_patch(to: ~p"/decks")}

      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    user = socket.assigns.current_scope.user
    deck = Decks.get_deck!(id)

    if deck.user_id == user.id do
      {:ok, _} = Decks.delete_deck(deck)
      decks = Decks.list_decks(user)

      {:noreply,
       socket
       |> assign(:decks, decks)
       |> put_flash(:info, "Deck deleted")}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("validate", %{"deck" => deck_params}, socket) do
    changeset =
      socket.assigns.deck
      |> Decks.change_deck(deck_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  defp deck_stats(deck), do: Decks.deck_stats(deck)

  defp format_label(format) do
    format |> String.replace("_", " ") |> String.capitalize()
  end
end
