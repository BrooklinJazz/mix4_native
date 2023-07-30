defmodule Connect4Web.Connect4Live do
  use Connect4Web, :live_view
  use LiveViewNative.LiveView
  alias Connect4.GamesServer
  alias Connect4.Games.Board
  alias Connect4.Games.Game
  alias Connect4Web.Presence

  @impl true
  def mount(_params, session, socket) do
    current_player = session["current_player"]
    games_server_pid = session["game_server_pid"] || GamesServer
    game = GamesServer.find_game_by_player(games_server_pid, current_player)

    if game do
      Connect4Web.Endpoint.subscribe("game:#{game.id}")
    end

    Connect4Web.Endpoint.subscribe("player:#{current_player.id}")
    Connect4Web.Endpoint.subscribe(Presence.players_topic())

    Presence.track_player(self(), current_player, (game && game.id) || nil)

    Process.send_after(self(), :tick, 1000)

    socket =
      socket
      |> assign(:game, game)
      |> assign(:current_player, current_player)
      |> assign(:waiting, GamesServer.waiting?(games_server_pid, current_player))
      |> assign(:time_remaining, nil)
      |> assign(
        :outgoing_requests,
        GamesServer.outgoing_requests(games_server_pid, current_player)
      )
      |> assign(
        :incoming_requests,
        GamesServer.incoming_requests(games_server_pid, current_player)
      )
      |> assign_players()
      # platform_id and games_server_pid set for testing purposes
      |> assign(:platform_id, session["platform_id"] || socket.assigns.platform_id)
      |> assign(:games_server_pid, games_server_pid)

    {:ok, socket}
  end

  @impl true
  def render(%{platform_id: :web} = assigns) do
    ~H"""
    Your name is: <%= @current_player.name %>
    <main class="flex h-screen gap-x-4 w-[80%] items-center justify-center m-auto">
      <section id="players-list" class="flex flex-col h-full w-1/3 max-h-[32rem] max-w-80">
        <h2>Players Online: <%= Enum.count(@players) %></h2>
        <.table id="players" rows={@players}>
          <:col :let={player} label="username"><%= player.struct.name %></:col>
          <:col :let={player}>
            <%= cond do %>
              <% player.game_id -> %>
                <.button id={"currently-playing-#{player.struct.id}"} disabled>
                  Already In Game
                </.button>
              <% player.struct in @outgoing_requests -> %>
                <.button id={"request-player-#{player.struct.id}"} disabled>
                  Requested
                </.button>
              <% player.struct in @incoming_requests -> %>
                <.button
                  id={"request-player-#{player.struct.id}"}
                  phx-click="request"
                  phx-value-player_id={player.struct.id}
                >
                  Accept Request
                </.button>
              <% true -> %>
                <.button
                  id={"request-player-#{player.struct.id}"}
                  phx-click="request"
                  phx-value-player_id={player.struct.id}
                >
                  Request
                </.button>
            <% end %>
          </:col>
        </.table>
      </section>
      <article
        id="game"
        class="w-2/3 h-[32rem] flex items-center justify-center border-2 border-black"
      >
        <%= cond do %>
          <% @waiting -> %>
            <p>Waiting for opponent</p>
          <% @game == nil -> %>
            <.button id="play-online" phx-click="play-online">Play Online</.button>
          <% Game.winner(@game) == @current_player -> %>
            <p>You win!</p>
            <.button id="play-online" phx-click="play-online">Play Again</.button>
          <% Game.winner(@game) && Game.winner(@game)  != @current_player -> %>
            <p>You lose...</p>
            <.button id="play-online" phx-click="play-online">Play Again</.button>
          <% @game -> %>
            <div>
              <article class="flex justify-between w-full">
                <p><%= @current_player.name %></p>
                <%= if @current_player == Game.current_turn(@game) do %>
                  <p id="your-turn">Your turn</p>
                <% else %>
                  <p id="opponents-turn">Waiting for opponent</p>
                <% end %>
                <p><%= Game.opponent(@game, @current_player).name %></p>
              </article>
              <article class="flex">
                <div class={"w-10 #{player_color(@game, @current_player)} #{Game.current_turn(@game) == Game.opponent(@game, @current_player) && "opacity-30"}"} />
                <.board game={@game} current_player={@current_player} />
                <div class={"w-10 #{opponent_color(@game, @current_player)}  #{Game.current_turn(@game) == @current_player && "opacity-30"}"} />
              </article>
            </div>
            <.button id="quit-game" phx-click="quit">Quit</.button>
            <p id="turn-timer">
              <%= @time_remaining %>
            </p>
        <% end %>
      </article>
    </main>
    """
  end

  @impl true
  def render(%{platform_id: :swiftui} = assigns) do
    ~SWIFTUI"""
    <Section>
    <%= cond do %>
      <% @waiting -> %>
        <Text>Waiting for opponent</Text>
      <% @game == nil -> %>
        <Button id="play-online" phx-click="play-online">Play Online</Button>
      <% Game.winner(@game) == @current_player -> %>
        <Text>You win!</Text>
        <Button id="play-online" phx-click="play-online">Play Online</Button>
      <% Game.winner(@game) && Game.winner(@game)  != @current_player -> %>
        <Text>You lose...</Text>
        <Button id="play-online" phx-click="play-online">Play Online</Button>
      <% @game -> %>
        <%= if @current_player == Game.current_turn(@game) do %>
          <Text id="your-turn">Your turn</Text>
        <% else %>
          <Text id="opponents-turn">Opponent turn</Text>
        <% end %>
        <HStack id="board">
          <%= for {column, x} <- Enum.with_index(Board.transpose(Game.board(@game))) do %>
            <VStack id={"column-#{x}"} phx-click="drop" phx-value-column={x}>
              <%= for {cell, y} <- Enum.with_index(column) do %>
                <Circle id={"cell-#{x}-#{y}"} data-color={cell} fill-color={platform_color(:swiftui, cell)} />
              <% end %>
            </VStack>
          <% end %>
        </HStack>
        <Button id="quit-game" phx-click="quit">Quit</Button>
      <% end %>
    </Section>
    """
  end

  def handle_event("drop", %{"column" => column}, socket) do
    updated_game =
      Game.drop(socket.assigns.game, socket.assigns.current_player, String.to_integer(column))

    GamesServer.update(socket.assigns.games_server_pid, updated_game)
    {:noreply, socket}
  end

  def handle_event("play-online", _params, socket) do
    GamesServer.join(socket.assigns.games_server_pid, socket.assigns.current_player)
    {:noreply, assign(socket, :waiting, true)}
  end

  def handle_event("quit", _params, socket) do
    GamesServer.quit(socket.assigns.games_server_pid, socket.assigns.current_player)
    {:noreply, assign(socket, waiting: false, game: nil)}
  end

  def handle_event("request", %{"player_id" => player_id}, socket) do
    player = Enum.find(socket.assigns.players, fn %{struct: player} -> player.id == player_id end)

    GamesServer.request(
      socket.assigns.games_server_pid,
      socket.assigns.current_player,
      player.struct
    )

    {:noreply,
     assign(
       socket,
       :outgoing_requests,
       GamesServer.outgoing_requests(
         socket.assigns.games_server_pid,
         socket.assigns.current_player
       )
     )}
  end

  @impl true
  def handle_info({:game_started, game}, socket) do
    Phoenix.PubSub.subscribe(Connect4.PubSub, "game:#{game.id}")
    Presence.track_in_game(self(), socket.assigns.current_player, game.id)

    {:noreply,
     socket |> assign(:game, game) |> assign(:waiting, false) |> assign_time_remaining()}
  end

  @impl true
  def handle_info({:game_requested, incoming_request}, socket) do
    {:noreply,
     assign(socket, :incoming_requests, [incoming_request | socket.assigns.incoming_requests])}
  end

  def handle_info({:game_updated, game}, socket) do
    {:noreply, assign(socket, :game, game)}
  end

  def handle_info({:game_quit, player}, socket) do
    Presence.track_in_game(self(), socket.assigns.current_player, nil)

    socket =
      if(socket.assigns.current_player != player) do
        put_flash(socket, :error, "Your opponent left the game.")
      else
        socket
      end

    {:noreply,
     socket
     |> assign(:game, nil)
     |> assign_incoming_requests()
     |> assign_outgoing_requests()}
  end

  def handle_info(%{event: "presence_diff", payload: _payload}, socket) do
    {:noreply, assign_players(socket)}
  end

  def handle_info(:tick, socket) do
    Process.send_after(self(), :tick, 1000)

    if socket.assigns.game do
      {:noreply, assign_time_remaining(socket)}
    else
      {:noreply, socket}
    end
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

  defp assign_time_remaining(socket) do
    game = socket.assigns.game

    time_remaining =
      Game.turn_end_time(game)
      |> DateTime.diff(DateTime.utc_now(:second))
      |> max(0)

    current_player_ran_out_of_time =
      time_remaining == 0 and socket.assigns.current_player == Game.current_turn(game)

    if current_player_ran_out_of_time do
      # it's a bit hacky to handle running out of time in the LiveView, but it's an easy implementation for now.
      GamesServer.update(
        socket.assigns.games_server_pid,
        Game.run_out_of_time(game, socket.assigns.current_player)
      )
    end

    assign(socket, :time_remaining, time_remaining)
  end

  defp assign_incoming_requests(socket) do
    assign(
      socket,
      :incoming_requests,
      GamesServer.incoming_requests(
        socket.assigns.games_server_pid,
        socket.assigns.current_player
      )
    )
  end

  defp assign_outgoing_requests(socket) do
    assign(
      socket,
      :outgoing_requests,
      GamesServer.outgoing_requests(
        socket.assigns.games_server_pid,
        socket.assigns.current_player
      )
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

  defp board(assigns) do
    ~H"""
    <section id="board" class="flex gap-x-2 items-center justify-center bg-blue-400 p-3">
      <%= for {column, x} <- Enum.with_index(Board.transpose(Game.board(@game))) do %>
        <article
          id={"column-#{x}"}
          phx-click="drop"
          phx-value-column={x}
          class="flex flex-col gap-y-2 group cursor-pointer"
        >
          <%= for {cell, y} <- Enum.with_index(column) do %>
            <button
              id={"cell-#{x}-#{y}"}
              data-color={cell}
              class={"h-12 w-12 rounded-full #{platform_color(:web, cell)} #{hover_styles(@game, @current_player, x, y)}"}
            />
          <% end %>
        </article>
      <% end %>
    </section>
    """
  end

  defp platform_color(:web, cell) do
    case cell do
      :red -> "bg-red-400"
      :yellow -> "bg-yellow-400"
      _ -> "bg-black"
    end
  end

  defp platform_color(:swiftui, cell) do
    case cell do
      :red -> "#FF0000"
      :yellow -> "#FFC82F"
      nil -> "#000000"
    end
  end

  defp hover_styles(game, current_player, x, y) do
    should_display_hover_styles =
      Board.drop_index(game.board, x) == y && Game.current_turn(game) == current_player

    if should_display_hover_styles do
      "#{hover_color(game, current_player)} group-hover:opacity-50"
    else
      ""
    end
  end

  defp player_color(%Game{} = game, current_player) do
    player1 = Game.player1(game)
    player2 = Game.player2(game)

    case current_player do
      ^player1 -> "bg-red-500"
      ^player2 -> "bg-yellow-500"
    end
  end

  defp opponent_color(%Game{} = game, current_player) do
    player1 = Game.player1(game)
    player2 = Game.player2(game)

    case current_player do
      ^player1 -> "bg-yellow-500"
      ^player2 -> "bg-red-500"
    end
  end

  defp hover_color(%Game{} = game, current_player) do
    player1 = Game.player1(game)
    player2 = Game.player2(game)

    case current_player do
      ^player1 -> "group-hover:bg-red-500"
      ^player2 -> "group-hover:bg-yellow-500"
    end
  end
end
