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

    if game && connected?(socket) do
      Connect4Web.Endpoint.subscribe("game:#{game.id}")
    end

    if connected?(socket) do
      Connect4Web.Endpoint.subscribe("player:#{current_player.id}")
      Connect4Web.Endpoint.subscribe(Presence.players_topic())
      Presence.track_player(self(), current_player, (game && game.id) || nil)
      Process.send_after(self(), :tick, 1000)
    end

    socket =
      socket
      |> assign(:game, game)
      |> assign(:current_player, current_player)
      |> assign(:waiting, GamesServer.waiting?(games_server_pid, current_player))
      |> assign(:time_remaining, nil)
      # platform_id and games_server_pid set for testing purposes
      |> assign(:platform_id, session["platform_id"] || socket.assigns.platform_id)
      |> assign(:games_server_pid, games_server_pid)
      |> assign_incoming_requests()
      |> assign_outgoing_requests()
      |> assign_players()

    {:ok, socket}
  end

  @impl true
  def render(%{platform_id: :web} = assigns) do
    ~H"""
    <main class="flex w-[80%] flex-col m-auto h-screen justify-center items-center">
      <p class="mb-4">Welcome <%= @current_player.name %></p>
      <section class="gap-x-8 w-full flex flex-col-reverse sm:flex-row">
        <section id="players-list" class="flex flex-col flex-grow min-w-max sm:w-2/5">
          <h2>Players Online: <%= Enum.count(@players) %></h2>
          <ul>
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
        </section>
        <section id="game" class="flex flex-col sm:w-2/5 h-96 justify-center">
          <%= cond do %>
            <% @waiting -> %>
              <.empty_board />
              <div class="flex justify-center items-center gap-x-2 bg-zinc-900 p-2 text-white">
                <p>Waiting for opponent...</p>
                <.icon name="hero-arrow-path" class="ml-1 w-3 h-3 animate-spin" />
              </div>
              <.button id="leave-queue" phx-click="leave-queue">Cancel</.button>
            <% @game == nil -> %>
              <.empty_board />
              <.button id="play-online" phx-click="play-online">Play Online</.button>
            <% Game.winner(@game) == @current_player -> %>
              <p>You win!</p>
              <.empty_board />
              <.button id="play-online" phx-click="play-online">Play Again</.button>
            <% Game.winner(@game) && Game.winner(@game)  != @current_player -> %>
              <p>You lose...</p>
              <.button id="play-online" phx-click="play-online">Play Again</.button>
            <% @game -> %>
              <.board game={@game} current_player={@current_player} />
              <article class="flex justify-between w-full">
                <p class={"py-2 flex flex-1 justify-center #{player_color(@game, @current_player)}"}>
                  <%= @current_player.name %>
                </p>
                <p class={"py-2 flex flex-1 justify-center #{player_color(@game, Game.opponent(@game, @current_player))}"}>
                  <%= Game.opponent(@game, @current_player).name %>
                </p>
              </article>
              <article class="w-full bg-gray-100 p-2 flex justify-center gap-x-4">
                <%= if @current_player == Game.current_turn(@game) do %>
                  <p id="your-turn">Your turn</p>
                <% else %>
                  <p id="opponents-turn">Waiting for opponent</p>
                <% end %>
                <p id="turn-timer" class="w-8">
                  <%= @time_remaining %>
                </p>
              </article>
              <.button class="ml-auto w-1/3" id="quit-game" phx-click="quit">Quit</.button>
          <% end %>
        </section>
      </section>
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

  def handle_event("leave-queue", _params, socket) do
    GamesServer.leave_queue(socket.assigns.games_server_pid, socket.assigns.current_player)
    {:noreply, assign(socket, :waiting, false)}
  end

  def handle_event("drop", %{"column" => column}, socket) do
    GamesServer.drop(
      socket.assigns.games_server_pid,
      socket.assigns.game.id,
      socket.assigns.current_player,
      String.to_integer(column)
    )

    {:noreply, socket}
  end

  def handle_event("play-online", _params, socket) do
    GamesServer.join_queue(socket.assigns.games_server_pid, socket.assigns.current_player)
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

  defp empty_board(assigns) do
    ~H"""
    <section class="flex gap-x-2 bg-blue-500 p-2">
      <%= for column <- Board.new() |> Board.transpose() do %>
        <article class="flex flex-col flex-1 gap-y-2 h-full">
          <%= for _cell <- Enum.with_index(column) do %>
            <button class="cursor-auto">
              <svg
                class="fill-black"
                style="width: 100%; height: 100%;vertical-align: middle;overflow: hidden;"
                viewBox="0 0 1024 1024"
                version="1.1"
                xmlns="http://www.w3.org/2000/svg"
              >
                <path d="M507.768595 892.826446a313.123967 313.123967 0 0 1-223.418182-96.476033 327.087603 327.087603 0 0 1 4.231405-455.722314l196.33719-196.76033a39.775207 39.775207 0 0 1 30.042975-12.694215 42.31405 42.31405 0 0 1 30.042976 13.117355l192.952066 199.722314a327.087603 327.087603 0 0 1-3.808265 455.722314A310.161983 310.161983 0 0 1 507.768595 892.826446z" />
              </svg>
            </button>
          <% end %>
        </article>
      <% end %>
    </section>
    """
  end

  defp board(assigns) do
    ~H"""
    <section id="board" class="flex gap-x-2 bg-blue-500 p-2">
      <%= for {column, x} <- Enum.with_index(Board.transpose(Game.board(@game))) do %>
        <article
          id={"column-#{x}"}
          phx-click="drop"
          phx-value-column={x}
          class="flex flex-col flex-1 gap-y-2 group cursor-pointer h-full"
        >
          <%= for {cell, y} <- Enum.with_index(column) do %>
            <button id={"cell-#{x}-#{y}"} data-color={cell}>
              <svg
                class={"#{cell_fill_styles(@game, @current_player, {x, y}, cell)} "}
                style="width: 100%; height: 100%;vertical-align: middle;overflow: hidden;"
                viewBox="0 0 1024 1024"
                version="1.1"
                xmlns="http://www.w3.org/2000/svg"
              >
                <path d="M507.768595 892.826446a313.123967 313.123967 0 0 1-223.418182-96.476033 327.087603 327.087603 0 0 1 4.231405-455.722314l196.33719-196.76033a39.775207 39.775207 0 0 1 30.042975-12.694215 42.31405 42.31405 0 0 1 30.042976 13.117355l192.952066 199.722314a327.087603 327.087603 0 0 1-3.808265 455.722314A310.161983 310.161983 0 0 1 507.768595 892.826446z" />
              </svg>
            </button>
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

  defp cell_fill_styles(game, player, {x, y}, cell) do
    should_display_hover_styles =
      Board.drop_index(game.board, x) == y && Game.current_turn(game) == player

    player1 = Game.player1(game)
    player2 = Game.player2(game)

    case {player, should_display_hover_styles, cell} do
      {_, _, :red} -> "fill-purple-400"
      {_, _, :yellow} -> "fill-orange-400"
      {^player1, true, _} -> "group-hover:fill-purple-400 fill-black"
      {^player2, true, _} -> "group-hover:fill-orange-400 fill-black"
      _ -> "fill-black"
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
