defmodule Mix4Web.GameLive do
  alias Mix4Web.Presence
  alias Mix4.GamesServer
  use Mix4Web, :live_view
  use LiveViewNative.LiveView
  alias Mix4.Games.Board
  alias Mix4.Games.Game

  @impl true
  def mount(%{"game_id" => game_id}, %{"current_player" => current_player}, socket) do
    get_connect_params(socket)
    game = GamesServer.find_game_by_id(game_id)

    if connected?(socket) do
      Mix4Web.Endpoint.subscribe("player:#{current_player.id}")
      Mix4Web.Endpoint.subscribe("game:#{game_id}")
      Presence.track_player(self(), current_player, game_id)
      Presence.track_in_game(self(), current_player, game.id)
      send(self(), :tick)
    end

    if game && current_player in [Game.player1(game), Game.player2(game)] do
      {:ok,
       socket
       |> assign(:game, game)
       |> assign(:current_player, current_player)
       |> assign(:opponent, Game.opponent(game, current_player))
       |> assign_time_remaining()}
    else
      {:ok, redirect(socket, to: "/")}
    end
  end

  @impl true
  def render(%{platform_id: :web} = assigns) do
    ~H"""
    <main class="w-2/3 md:w-1/2 lg:w-1/4 mx-auto h-screen max-w-[40rem] flex flex-col justify-center items-center">
      <section class="flex justify-between m-2 w-full gap-x-2">
        <p class={[
          "w-full p-5",
          @current_player == Game.player1(@game) and Game.current_turn(@game) == @current_player &&
            "bg-purple-400",
          @current_player == Game.player2(@game) and Game.current_turn(@game) == @current_player &&
            "bg-orange-400",
          @current_player == Game.player1(@game) and Game.current_turn(@game) == @opponent &&
            "bg-purple-300",
          @current_player == Game.player2(@game) and Game.current_turn(@game) == @opponent &&
            "bg-orange-300"
        ]}>
          <%= @current_player.name %>
          <%= if not Game.finished?(@game) and @current_player == Game.current_turn(@game),
            do: "#{@time_remaining}s" %>
        </p>
        <p class={[
          "w-full p-5",
          @opponent == Game.player1(@game) and Game.current_turn(@game) == @opponent &&
            "bg-purple-400",
          @opponent == Game.player2(@game) and Game.current_turn(@game) == @opponent &&
            "bg-orange-400",
          @opponent == Game.player1(@game) and Game.current_turn(@game) == @current_player &&
            "bg-purple-300",
          @opponent == Game.player2(@game) and Game.current_turn(@game) == @current_player &&
            "bg-orange-300"
        ]}>
          <%= @opponent.name %>
          <%= if not Game.finished?(@game) and @opponent == Game.current_turn(@game),
            do: "#{@time_remaining}s" %>
        </p>
      </section>
      <section id="board" class="bg-blue-400 w-full p-2 flex">
        <button
          :for={{column, x} <- indexed_columns(@game)}
          disabled={!!Game.winner(@game)}
          id={"column-#{x}"}
          phx-click="drop"
          phx-value-column={x}
          class="group flex-grow"
        >
          <div
            :for={{cell, y} <- Enum.with_index(column)}
            id={"cell-#{x}-#{y}"}
            data-cell={cell}
            class={[
              "aspect-square rounded-full m-2",
              cell == :player1 && "bg-purple-400",
              cell == :player2 && "bg-orange-400",
              cell == nil && "bg-black",
              hover_style(@game, @current_player, {x, y})
            ]}
          >
          </div>
        </button>
      </section>

      <%= cond do %>
        <% Game.winner(@game) == @current_player -> %>
          <p class={["w-full m-2 p-5 bg-green-400"]}>You win!</p>
        <% Game.winner(@game) == @opponent -> %>
          <p class={["w-full m-2 p-5 bg-red-400"]}>You lose..</p>
        <% Game.current_turn(@game) == @current_player -> %>
          <p class={["w-full m-2 p-5 bg-gray-400"]}>Your Turn</p>
        <% Game.current_turn(@game) == @opponent -> %>
          <p class={["w-full m-2 p-5 bg-gray-200"]}>Waiting for opponent</p>
      <% end %>

      <.button class="py-5 w-1/3 ml-auto" id="quit" phx-click="quit">
        <%= if Game.winner(@game), do: "Exit", else: "Give Up" %>
      </.button>
    </main>
    """
  end

  def render(%{platform_id: :swiftui} = assigns) do
    ~SWIFTUI"""
    <HStack id="board">
    <%= for {column, x} <- Enum.with_index(Board.transpose(Game.board(@game))) do %>
      <VStack id={"column-#{x}"} phx-click="drop" phx-value-column={x}>
        <%= for {cell, y} <- Enum.with_index(column) do %>
          <Circle id={"cell-#{x}-#{y}"} data-color={cell} fill-color={hex_code(cell)} />
        <% end %>
      </VStack>
    <% end %>
    </HStack>
    """
  end

  defp hex_code(cell) do
    case cell do
      :player1 -> "#FF0000"
      :player2 -> "#FFC82F"
      nil -> "#000000"
    end
  end

  defp hover_style(game, current_player, {x, y}) do
    should_display_hover_style =
      !Game.winner(game) and Game.current_turn(game) == current_player and
        y == Board.drop_index(game.board, x)

    cond do
      current_player == Game.player1(game) && should_display_hover_style ->
        "group-hover:bg-purple-400"

      current_player == Game.player2(game) && should_display_hover_style ->
        "group-hover:bg-orange-400"

      true ->
        ""
    end
  end

  @impl true
  def handle_event("drop", %{"column" => column}, socket) do
    GamesServer.drop(
      socket.assigns.game.id,
      socket.assigns.current_player,
      String.to_integer(column)
    )

    {:noreply, socket}
  end

  def handle_event("quit", _params, socket) do
    GamesServer.quit(socket.assigns.current_player)
    {:noreply, redirect(socket, to: "/")}
  end

  @impl true
  def handle_info({:game_updated, game}, socket) do
    {:noreply, assign(socket, :game, game)}
  end

  @impl true
  def handle_info({:game_quit, _player}, socket) do
    socket =
      socket
      |> put_flash(:error, "Your opponent left the game.")
      |> assign(:game, %Game{socket.assigns.game | winner: socket.assigns.current_player})

    {:noreply, socket}
  end

  def handle_info(:tick, socket) do
    Process.send_after(self(), :tick, 1000)

    if Game.finished?(socket.assigns.game) do
      {:noreply, socket}
    else
      {:noreply, assign_time_remaining(socket)}
    end
  end

  defp assign_time_remaining(socket) do
    game = socket.assigns.game

    time_remaining =
      Game.turn_end_time(game)
      |> DateTime.diff(DateTime.utc_now(), :second)
      |> max(0)

    current_player_ran_out_of_time =
      time_remaining == 0 and socket.assigns.current_player == Game.current_turn(game)

    if current_player_ran_out_of_time do
      # it's a bit hacky to handle running out of time in the LiveView, but it's an easy implementation for now.
      GamesServer.update(Game.run_out_of_time(game, socket.assigns.current_player))
    end

    assign(socket, :time_remaining, time_remaining)
  end

  defp indexed_columns(game) do
    game |> Game.board() |> Board.transpose() |> Enum.with_index()
  end
end
