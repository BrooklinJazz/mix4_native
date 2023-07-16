defmodule Connect4Web.Connect4Live do
  use Connect4Web, :live_view
  use LiveViewNative.LiveView

  def mount(_params, _session, socket) do
    {:ok, assign(socket, board_matrix: Connect4.initial_board())}
  end

  def render(%{platform_id: :web} = assigns) do
    ~H"""
    Connect4
    """
  end

  def render(%{platform_id: :swiftui} = assigns) do
    ~SWIFTUI"""
    <Text><%= board(@board_matrix) %></Text>
    <Table>
      <Group template={:columns}>
        <TableColumn id="1">
          <Text>Column1</Text>
        </TableColumn>
        <TableColumn id="2">
          <Text>Column1</Text>
        </TableColumn>
        <TableColumn id="3">
          <Text>Column1</Text>
        </TableColumn>
      </Group>
      <Group template={:rows}>
        <TableRow id="r1">
          <Text>Row1</Text>
        </TableRow>
        <TableRow id="r2">
          <Text>Row1</Text>
        </TableRow>
        <TableRow id="r3">
          <Text>Row1</Text>
        </TableRow>
      </Group>
    </Table>

    """
  end

  def board(board_matrix) do
    """
    <Text>Test</Text>
    """
  end
end
