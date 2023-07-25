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
      Phoenix.PubSub.subscribe(Connect4.PubSub, "game:#{game.id}")
    end

    Phoenix.PubSub.subscribe(Connect4.PubSub, "player:#{current_player.id}")

    socket =
      socket
      |> assign(:game, game)
      |> assign(:platform_id, session["platform_id"] || socket.assigns.platform_id)
      |> assign(:current_player, current_player)
      # set for testing purposes
      |> assign(:games_server_pid, games_server_pid)

    {:ok, socket}
  end

  @impl true
  def render(%{platform_id: :web} = assigns) do
    ~H"""
    <%= cond do %>
      <% @game == nil -> %>
        <h1><%= @current_player.name %></h1>
        <.button id="play-online" phx-click="play-online">Play Online</.button>
        <.button id="player-vs-player" phx-click="play-vs-player">Player vs Player</.button>
        <.button id="player-vs-ai" phx-click="play-vs-ai">Player vs AI</.button>
      <% Game.winner(@game) == @current_player -> %>
        <h1>You win!</h1>
      <% Game.winner(@game) && Game.winner(@game)  != @current_player -> %>
        <h1>You lose...</h1>
      <% @game -> %>
        <section id="board" class="flex h-screen w-full gap-x-2 items-center justify-center">
          <%= for {column, x} <- Enum.with_index(Board.transpose(Game.board(@game))) do %>
            <article
              id={"column-#{x}"}
              phx-click="drop"
              phx-value-column={x}
              class="flex flex-col gap-y-2 "
            >
              <%= for {cell, y} <- Enum.with_index(column) do %>
                <button
                  id={"cell-#{x}-#{y}"}
                  data-color={cell}
                  class={"h-12 w-12 rounded-full #{platform_color(:web, cell)}"}
                />
              <% end %>
            </article>
          <% end %>
        </section>
    <% end %>
    """
  end

  @impl true
  def render(%{platform_id: :swiftui} = assigns) do
    ~SWIFTUI"""
    <Section>
    <%= cond do %>
      <% @game == nil -> %>
        <Button id="play-online" phx-click="play-online">Play Online</Button>
        <Button id="player-vs-player" phx-click="play-vs-player">Player vs Player</Button>
        <Button id="player-vs-ai" phx-click="play-vs-ai">Player vs AI</Button>
      <% Game.winner(@game) == @current_player -> %>
        <Text>You win!</Text>
      <% Game.winner(@game) && Game.winner(@game)  != @current_player -> %>
        <Text>You lose...</Text>
      <% @game -> %>
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
    {:noreply, socket}
  end

  @impl true
  def handle_info({:game_started, game}, socket) do
    Phoenix.PubSub.subscribe(Connect4.PubSub, "game:#{game.id}")

    {:noreply, assign(socket, :game, game)}
  end

  def handle_info({:game_updated, game}, socket) do
    {:noreply, assign(socket, :game, game)}
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
end
