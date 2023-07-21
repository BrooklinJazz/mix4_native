defmodule Connect4Web.Connect4Live do
  use Connect4Web, :live_view
  use LiveViewNative.LiveView

  def mount(params, _session, socket) do
    socket =
      assign(socket, board: Connect4.initial_board(), player: :red, winner: nil, count: 0)
      |> assign_platform_id(params)

    {:ok, socket}
  end

  def render(%{platform_id: :web} = assigns) do
    ~H"""
    <section class="flex h-screen w-full gap-x-2 items-center justify-center">
      <%= if @winner do %>
        <h1><%= @winner %> wins!</h1>
      <% else %>
        <%= for {column, x} <- Enum.with_index(Connect4.transpose(@board)) do %>
          <article
            id={"column-#{x}"}
            phx-click="drop"
            phx-value-column={x}
            class="flex flex-col gap-y-2 "
          >
            <%= for {cell, y} <- Enum.with_index(column) do %>
              <button id={"cell-#{x}-#{y}"} class={"h-12 w-12 rounded-full #{tailwind_color(cell)}"}>
              </button>
            <% end %>
          </article>
        <% end %>
      <% end %>
    </section>
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
                <Circle id={"cell-#{x}-#{y}"} phx-click="drop" phx-value-column={x} fill-color={color_code(cell)} />
              <% end %>
            </HStack>
          <% end %>
        </VStack>
      <% end %>
    </Section>
    """
  end

  def color_code(cell) do
    case cell do
      :red -> "#FF0000"
      :yellow -> "#FFC82F"
      nil -> "#000000"
    end
  end

  def tailwind_color(cell) do
    case cell do
      :red -> "bg-red-400"
      :yellow -> "bg-yellow-400"
      _ -> "bg-black"
    end
  end

  def handle_event("increment", _params, socket) do
    {:noreply, assign(socket, :count, socket.assigns.count + 1)}
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
    assign(socket, :winner, winner)
  end

  defp assign_platform_id(socket, params) do
    case params do
      %{"platform_id" => platform_id} ->
        assign(socket, :platform_id, String.to_existing_atom(platform_id))

      _ ->
        socket
    end
  end
end
