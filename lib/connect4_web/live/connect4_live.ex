defmodule Connect4Web.Connect4Live do
  use Connect4Web, :live_view
  use LiveViewNative.LiveView
  alias Connect4.GamesServer
  alias Connect4.Games.Game
  alias Connect4.Games.Board

  @impl true
  def mount(_params, session, socket) do
    current_player = session["current_player"]
    games_server_pid = session["game_server_pid"] || GamesServer
    game = GamesServer.find_game(games_server_pid, current_player)

    if game do
      Connect4Web.Endpoint.subscribe("game:#{game.id}")
    end

    Connect4Web.Endpoint.subscribe("player:#{current_player.id}")

    socket =
      socket
      |> assign(:game, game)
      |> assign(:current_player, current_player)
      # platform_id and games_server_pid set for testing purposes
      |> assign(:platform_id, session["platform_id"] || socket.assigns.platform_id)
      |> assign(:games_server_pid, games_server_pid)
      |> assign(:waiting, GamesServer.waiting?(games_server_pid, current_player))

    {:ok, socket}
  end

  @impl true
  def render(%{platform_id: :web} = assigns) do
    ~H"""
    Your name is: <%= @current_player.name %>
    <section class="flex flex-col h-screen w-full items-center justify-center">
      <%= cond do %>
        <% @waiting -> %>
          <p>Waiting for opponent</p>
        <% @game == nil -> %>
          <p><%= @current_player.name %></p>
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
      <% end %>
      <%= if @game do %>
        <.button id="quit-game" phx-click="quit">Quit</.button>
      <% end %>
    </section>
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

  @impl true
  def handle_info({:game_started, game}, socket) do
    Phoenix.PubSub.subscribe(Connect4.PubSub, "game:#{game.id}")

    {:noreply, socket |> assign(:game, game) |> assign(:waiting, false)}
  end

  def handle_info({:game_updated, game}, socket) do
    {:noreply, assign(socket, :game, game)}
  end

  def handle_info(:game_quit, socket) do
    {:noreply, assign(socket, :game, nil)}
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
