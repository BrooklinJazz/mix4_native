defmodule Connect4Web.Connect4Live do
  use Connect4Web, :live_view
  use LiveViewNative.LiveView
  alias Connect4.GameQueue
  alias Connect4.Game

  @impl true
  def mount(_params, session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Connect4.PubSub, "lobby")
    end

    current_player = session["current_player"]

    socket =
      socket
      |> assign(:game, nil)
      |> assign(:platform_id, session["platform_id"] || socket.assigns.platform_id)
      |> assign(:current_player, current_player)
      |> assign(:status, :idle)

    {:ok, socket}
  end

  @impl true
  def render(%{platform_id: :web} = assigns) do
    ~H"""
    <p><%= IO.inspect(@current_player).name %></p>
    <%= case @status do %>
      <% :winner -> %>
        <h1>You win!</h1>
      <% :loser -> %>
        <h1>You lose...</h1>
      <% :waiting -> %>
        <h1>Waiting for opponent</h1>
      <% :playing -> %>
        <h1 id="opponent">Opponent: <%= @opponent.name %></h1>
        <section id="board" class="flex h-screen w-full gap-x-2 items-center justify-center">
          <%= for {column, x} <- Enum.with_index(Connect4.transpose(@game.board)) do %>
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
      <% _ -> %>
        <.button id="play-online" phx-click="play-online">Play Online</.button>
        <.button id="player-vs-player" phx-click="play-vs-player">Player vs Player</.button>
        <.button id="player-vs-ai" phx-click="play-vs-ai">Player vs AI</.button>
    <% end %>
    """
  end

  @impl true
  def render(%{platform_id: :swiftui} = assigns) do
    ~SWIFTUI"""
    <Section>
      <%= case @status do %>
        <% :winner -> %>
          <Text>You win!</Text>
        <% :loser -> %>
          <Text>You lose...</Text>
        <% :waiting -> %>
          <Text>Waiting for opponent</Text>
        <% :playing -> %>
          <Text id="opponent">Opponent: <%= @opponent.name %></Text>
          <HStack id="board">
            <%= for {column, x} <- Enum.with_index(Connect4.transpose(@game.board)) do %>
              <VStack id={"column-#{x}"} phx-click="drop" phx-value-column={x}>
                <%= for {cell, y} <- Enum.with_index(column) do %>
                  <Circle id={"cell-#{x}-#{y}"} data-color={cell} fill-color={platform_color(:swiftui, cell)} />
                <% end %>
              </VStack>
            <% end %>
          </HStack>
        <% _ -> %>
          <Button id="play-online" phx-click="play-online">Play Online</Button>
          <Button id="player-vs-player" phx-click="play-vs-player">Player vs Player</Button>
          <Button id="player-vs-ai" phx-click="play-vs-ai">Player vs AI</Button>
      <% end %>
    </Section>
    """
  end

  def handle_event("drop", %{"column" => column}, socket) do
    IO.inspect(column, label: "DROPPING")
    Game.drop(socket.assigns.game_pid, socket.assigns.current_player, String.to_integer(column))
    {:noreply, socket}
  end

  def handle_event("play-online", _params, socket) do
    GameQueue.join(socket.assigns.current_player)
    {:noreply, assign(socket, :status, :waiting)}
  end

  @impl true
  def handle_info({:game_started, pid}, socket) do
    opponent = Game.opponent(pid, socket.assigns.current_player)
    game = Game.game(pid)

    {:noreply,
     socket
     |> assign(:status, :playing)
     |> assign(:game, game)
     |> assign(:game_pid, pid)
     |> assign(:opponent, opponent)}
  end

  def handle_info({:game_updated, game}, socket) do
    current_player = socket.assigns.current_player
    opponent = socket.assigns.opponent

    socket =
      case game.winner do
        ^current_player -> assign(socket, :status, :winner)
        ^opponent -> assign(socket, :status, :loser)
        _ -> socket
      end

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
