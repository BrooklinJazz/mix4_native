defmodule Connect4Web.Connect4Live do
  use Connect4Web, :live_view
  use LiveViewNative.LiveView

  def mount(_params, _session, socket) do
    {:ok, assign(socket, board: Connect4.initial_board(), player: :red, winner: nil, count: 0)}
  end

  def render(%{platform_id: :web} = assigns) do
    ~H"""
    Connect4
    """
  end

  def render(%{platform_id: :swiftui} = assigns) do
    ~SWIFTUI"""
    <Section>
      <%= if @winner do %>
        <Text>
            <%= @winner %> wins!
        </Text>
      <% else %>
        <VStack id="board">
          <%= for {row, y} <- Enum.with_index(@board) do %>
            <HStack id={inspect(y)}>
              <%= for {cell, x} <- Enum.with_index(row) do %>
                <Circle id={inspect({x, y})} phx-click="drop" phx-value-column={x} fill-color={color(cell)} />
              <% end %>
            </HStack>
          <% end %>
        </VStack>
      <% end %>
    </Section>
    """
  end
  def test(), do: true

  def color(cell) do
    case cell do
      :red -> "#FF0000"
      :yellow -> "#FFC82F"
      nil -> "#000000"
    end
  end

  def handle_event("increment", _params, socket) do
    {:noreply, assign(socket, :count ,socket.assigns.count + 1)}
  end
  def handle_event("drop", %{"column" => column}, socket) do
    {:noreply,
     socket
     |> drop_disc(String.to_integer(column))
     |> switch_player()
     |> check_winner()}
  end

  def drop_disc(socket, column) do
    assign(
      socket,
      :board,
      Connect4.drop(socket.assigns.board, column, socket.assigns.player)
    )
  end

  def switch_player(socket) do
    color =
      case socket.assigns.player do
        :yellow -> :red
        :red -> :yellow
      end

    assign(socket, :player, color)
  end

  def check_winner(socket) do
    winner = Connect4.winner!(socket.assigns.board)
    IO.inspect(winner, label: "WINNER")
    assign(socket, :winner, winner)
  end
end
