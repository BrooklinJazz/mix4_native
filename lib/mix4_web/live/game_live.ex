defmodule Mix4Web.GameLive do
  alias Mix4.GamesServer
  use Mix4Web, :live_view
  use LiveViewNative.LiveView
  alias Mix4.Games.Board
  alias Mix4.Games.Game

  def mount(%{"game_id" => game_id}, %{"current_player" => current_player}, socket) do
    get_connect_params(socket)
    game = GamesServer.find_game_by_id(game_id)
    IO.inspect(game_id)

    # Process.send_after(self(), :tick, 1000)
    if game do
      {:ok, assign(socket, :game, game)}
    else
      {:ok, redirect(socket, to: "/")}
    end
  end

  def render(%{platform_id: :web} = assigns) do
    ~H"""
    <h1>HELLO GAME</h1>
    """
  end

  def render(%{platform_id: :swiftui} = assigns) do
    ~SWIFTUI"""
    <Text>Hello Game</Text>
    """
  end

  #   <HStack id="board">
  #   <%= for {column, x} <- Enum.with_index(Board.transpose(Game.board(@game))) do %>
  #     <VStack id={"column-#{x}"} phx-click="drop" phx-value-column={x}>
  #       <%= for {cell, y} <- Enum.with_index(column) do %>
  #         <Circle id={"cell-#{x}-#{y}"} data-color={cell} fill-color={hex_code(cell)} />
  #       <% end %>
  #     </VStack>
  #   <% end %>
  # </HStack>

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

  def handle_event("drop", %{"column" => column}, socket) do
    GamesServer.drop(
      socket.assigns.games_server,
      socket.assigns.game.id,
      socket.assigns.current_player,
      String.to_integer(column)
    )

    {:noreply, socket}
  end

  def handle_event("quit", _params, socket) do
    GamesServer.quit(socket.assigns.games_server, socket.assigns.current_player)
    {:noreply, assign(socket, waiting: false, game: nil)}
  end

  def handle_info({:game_updated, game}, socket) do
    {:noreply, assign(socket, :game, game)}
  end

  def handle_info({:game_quit, player}, socket) do
    Presence.track_in_game(self(), socket.assigns.current_player, nil)

    socket =
      if(socket.assigns.current_player != player) do
        socket
        |> put_flash(:error, "Your opponent left the game.")
        |> redirect(to: ~p"/")
      else
        socket
      end
  end

  def handle_info(:tick, socket) do
    Process.send_after(self(), :tick, 1000)

    if socket.assigns.game do
      {:noreply, assign_time_remaining(socket)}
    else
      {:noreply, socket}
    end
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
        socket.assigns.games_server,
        Game.run_out_of_time(game, socket.assigns.current_player)
      )
    end

    assign(socket, :time_remaining, time_remaining)
  end
end
