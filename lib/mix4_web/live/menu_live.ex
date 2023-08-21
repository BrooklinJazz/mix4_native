defmodule Mix4Web.MenuLive do
  use Mix4Web, :live_view
  use LiveViewNative.LiveView
  alias Mix4.GamesServer
  alias Mix4Web.Presence

  @impl true
  def mount(_params, %{"current_player" => current_player} = _session, socket) do
    if connected?(socket) do
      Mix4Web.Endpoint.subscribe("player:#{current_player.id}")
      Mix4Web.Endpoint.subscribe(Presence.players_topic())
      Presence.track_player(self(), current_player, nil)
    end

    game = GamesServer.find_game_by_player(current_player)

    if game do
      {:ok, redirect(socket, to: ~p"/game/#{game}")}
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
          <p>
            Waiting for opponent <.icon name="hero-arrow-path" class="ml-1 w-3 h-3 animate-spin" />
          </p>
          <.button id="leave-queue" phx-click="leave-queue">
            Cancel
          </.button>
        <% else %>
          <.button id="play-online" phx-click="play-online">
            Play Online
          </.button>
        <% end %>
      </section>
    </main>
    """
  end

  def render(%{platform_id: :swiftui} = assigns) do
    ~SWIFTUI"""
    <VStack>
      <List id="players-list">
        <%= for player <- @players  do %>
          <HStack>
            <Text id={player.struct.id}><%= player.struct.name %></Text>
            <Spacer/>
            <%= cond do %>
              <% player.game_id -> %>
                <Button id={"currently-playing-#{player.struct.id}"} modifiers={disabled(true)}>
                  Already In Game
                </Button>
              <% player.struct in @outgoing_requests -> %>
                <Button id={"request-player-#{player.struct.id}"} modifiers={disabled(true)}>
                  Requested
                </Button>
              <% player.struct in @incoming_requests -> %>
                <Button
                  id={"request-player-#{player.struct.id}"}
                  phx-click="request"
                  phx-value-player_id={player.struct.id}
                >
                  Accept Request
                </Button>
              <% true -> %>
                <Button
                  id={"request-player-#{player.struct.id}"}
                  phx-click="request"
                  phx-value-player_id={player.struct.id}
                >
                  Request
                </Button>
            <% end %>
          </HStack>
        <% end %>
      </List>
      <%= if @waiting do %>
        <Text>Waiting for opponent</Text>
        <Button id="leave-queue" phx-click="leave-queue">Cancel</Button>
      <% else %>
        <Button id="play-online" phx-click="play-online" modifiers={frame(height: 100) |> font(font: {:system, :title2})}>Play Online</Button>
      <% end %>
    </VStack>
    """
  end

  @impl true
  def handle_event("leave-queue", _params, socket) do
    GamesServer.leave_queue(socket.assigns.current_player)
    {:noreply, assign(socket, :waiting, false)}
  end

  @impl true
  def handle_event("play-online", _params, socket) do
    GamesServer.join_queue(socket.assigns.current_player)
    {:noreply, assign(socket, :waiting, true)}
  end

  @impl true
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
    {:noreply, push_navigate(socket, to: ~p"/game/#{game}")}
  end

  @impl true
  def handle_info({:game_requested, incoming_request}, socket) do
    {:noreply,
     assign(socket, :incoming_requests, [incoming_request | socket.assigns.incoming_requests])}
  end

  @impl true
  def handle_info(%{event: "presence_diff", payload: _payload}, socket) do
    {:noreply, assign_players(socket)}
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

    assign(socket, players: players)
  end
end
