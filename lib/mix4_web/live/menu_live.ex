defmodule Mix4Web.MenuLive do
  use Mix4Web, :live_view
  use LiveViewNative.LiveView
  alias Mix4.GamesServer
  alias Mix4.Games.Board
  alias Mix4.Games.Game
  alias Mix4Web.Presence

  @impl true
  def mount(_params, %{"current_player" => current_player} = session, socket) do
    if connected?(socket) do
      Mix4Web.Endpoint.subscribe("player:#{current_player.id}")
      Mix4Web.Endpoint.subscribe(Presence.players_topic())
      # Presence.track_player(self(), current_player, (game && game.id) || nil)
      Presence.track_player(self(), current_player, nil)
    end

    game = GamesServer.find_game_by_player(current_player)

    if game do
      redirect(socket, to: ~p"/game/#{game}")
    else
      socket =
        socket
        |> assign(:current_player, current_player)
        |> assign(:waiting, GamesServer.waiting?(current_player))
        |> assign_incoming_requests()
        |> assign_outgoing_requests()
        |> assign_players()

      {:ok, socket}
    end
  end

  @impl true
  def render(%{platform_id: :web} = assigns) do
    ~H"""
    <main class="flex w-screen h-screen justify-center items-center">
      <section id="players-list" class="flex flex-col w-1/2">
        <h2 class="mb-2">Players Online: <%= Enum.count(@players) %></h2>
        <ul class="h-[20rem] bg-gray-100 overflow-auto">
          <li
            :for={player <- @players}
            class="flex justify-between items-center p-2 border-t-2 border-gray-300"
          >
            <h2><%= player.struct.name %></h2>
            <%= cond do %>
              <% player.game_id -> %>
                <.button class="w-1/2" id={"currently-playing-#{player.struct.id}"} disabled>
                  Already In Game
                </.button>
              <% player.struct in @outgoing_requests -> %>
                <.button class="w-1/2" id={"request-player-#{player.struct.id}"} disabled>
                  Requested
                </.button>
              <% player.struct in @incoming_requests -> %>
                <.button
                  id={"request-player-#{player.struct.id}"}
                  class="w-1/2"
                  phx-click="request"
                  phx-value-player_id={player.struct.id}
                >
                  Accept Request
                </.button>
              <% true -> %>
                <.button
                  id={"request-player-#{player.struct.id}"}
                  class="w-1/2"
                  phx-click="request"
                  phx-value-player_id={player.struct.id}
                >
                  Request
                </.button>
            <% end %>
          </li>
        </ul>
        <%= if @waiting do %>
          <.button phx-click="leave-queue">
            Waiting...
          </.button>
        <% else %>
          <.button phx-click="play-online">
            Play Online
          </.button>
        <% end %>
      </section>
    </main>
    """
  end

  def render(%{platform_id: :swiftui} = assigns) do
    ~SWIFTUI"""
    <Section>
      <%= if @waiting do %>
        <Button id="leave-queue" phx-click="leave-queue">Waiting..</Button>
      <% else %>
        <Button id="play-online" phx-click="play-online">Play Online</Button>
      <% end %>
    </Section>
    """
  end

  def handle_event("leave-queue", _params, socket) do
    GamesServer.leave_queue(socket.assigns.current_player)
    {:noreply, assign(socket, :waiting, false)}
  end

  def handle_event("play-online", _params, socket) do
    GamesServer.join_queue(socket.assigns.current_player)
    {:noreply, assign(socket, :waiting, true)}
  end

  def handle_event("request", %{"player_id" => player_id}, socket) do
    player = Enum.find(socket.assigns.players, fn %{struct: player} -> player.id == player_id end)

    GamesServer.request(socket.assigns.current_player, player.struct)

    {:noreply,
     assign(
       socket,
       :outgoing_requests,
       GamesServer.outgoing_requests(socket.assigns.current_player)
     )}
  end

  @impl true
  def handle_info({:game_started, game}, socket) do
    # Phoenix.PubSub.subscribe(Mix4.PubSub, "game:#{game.id}")
    # Presence.track_in_game(self(), socket.assigns.current_player, game.id)

    {:noreply, redirect(socket, to: ~p"/game/#{game}")}
    #  socket |> assign(:game, game) |> assign(:waiting, false) |> assign_time_remaining()}
  end

  @impl true
  def handle_info({:game_requested, incoming_request}, socket) do
    {:noreply,
     assign(socket, :incoming_requests, [incoming_request | socket.assigns.incoming_requests])}
  end

  def handle_info(%{event: "presence_diff", payload: _payload}, socket) do
    {:noreply, assign_players(socket)}
  end

  def sort_players(players, incoming_requests, outgoing_requests) do
    # this is likely a performance issue, but it's not a concern for this demo project
    incoming_players = Enum.filter(players, fn player -> player in incoming_requests end)
    outgoing_players = Enum.filter(players, fn player -> player in outgoing_requests end)

    no_request_players =
      Enum.filter(players, fn player ->
        player not in incoming_requests and player not in outgoing_requests
      end)

    incoming_players ++ outgoing_players ++ no_request_players
  end

  defp assign_incoming_requests(socket) do
    assign(
      socket,
      :incoming_requests,
      GamesServer.incoming_requests(socket.assigns.current_player)
    )
  end

  defp assign_outgoing_requests(socket) do
    assign(
      socket,
      :outgoing_requests,
      GamesServer.outgoing_requests(socket.assigns.current_player)
    )
  end

  defp assign_players(socket) do
    players =
      Enum.reject(Presence.players(), fn player ->
        player.struct.id == socket.assigns.current_player.id
      end)

    assign(socket,
      players:
        sort_players(players, socket.assigns.incoming_requests, socket.assigns.outgoing_requests)
    )
  end

  defp hex_code(cell) do
    case cell do
      :red -> "#FF0000"
      :yellow -> "#FFC82F"
      nil -> "#000000"
    end
  end

  defp player_color(%Game{} = game, player) do
    player1 = Game.player1(game)
    player2 = Game.player2(game)

    case {player, Game.current_turn(game) == player} do
      {^player1, true} -> "bg-purple-400"
      {^player1, false} -> "bg-purple-400 opacity-40"
      {^player2, true} -> "bg-orange-400"
      {^player2, false} -> "bg-orange-400 opacity-40"
    end
  end
end
