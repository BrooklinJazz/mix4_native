defmodule Connect4 do
  @moduledoc """
  Connect4 keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """
  @initial_board [
    [nil, nil, nil, nil, nil, nil, nil],
    [nil, nil, nil, nil, nil, nil, nil],
    [nil, nil, nil, nil, nil, nil, nil],
    [nil, nil, nil, nil, nil, nil, nil],
    [nil, nil, nil, nil, nil, nil, nil],
    [nil, nil, nil, nil, nil, nil, nil]
  ]

  def initial_board, do: @initial_board

  def drop(board, column_index, marker) do
    nil_count = count_nils(board, column_index)

    case nil_count do
      0 ->
        {:error, :column_full}

      _ ->
        List.update_at(board, nil_count - 1, fn row ->
          List.replace_at(row, column_index, marker)
        end)
    end
  end

  def winners(board) do
    []
    |> Kernel.++(check_rows(board))
    |> Kernel.++(check_columns(board))
    |> Kernel.++(check_diagonals(board))
    |> Enum.filter(& &1)
  end

  def check_rows(board) do
    for x <- 0..4, y <- 0..5, do: check(:right, board, {x, y})
  end

  def check_columns(board) do
    for x <- 0..6, y <- 0..2, do: check(:up, board, {x, y})
  end

  def check_diagonals(board) do
    up_right_diagonals = for x <- 0..3, y <- 3..5, do: check(:up_right, board, {x, y})
    down_right_diagonals = for x <- 0..3, y <- 0..2, do: check(:down_right, board, {x, y})
    up_right_diagonals ++ down_right_diagonals
  end

  def check(direction, board, pos, acc \\ [], count \\ 4)

  def check(direction, board, {x, y} = pos, [prev_pos | _] = acc, 1) do
    current_cell = at(board, pos)
    prev_cell = at(board, walk(direction, prev_pos))

    if current_cell == prev_cell, do: [pos | acc]
  end

  def check(direction, board, {x, y} = pos, acc, count) do
    current_cell = at(board, pos)
    next_cell = at(board, walk(direction, pos))

    if current_cell && current_cell == next_cell do
      check(direction, board, walk(direction, pos), [pos | acc], count - 1)
    end
  end

  defp walk(:right, {x, y}), do: {x + 1, y}
  defp walk(:up, {x, y}), do: {x, y + 1}
  defp walk(:up_right, {x, y}), do: {x + 1, y - 1}
  defp walk(:down_right, {x, y}), do: {x + 1, y + 1}

  def check_rows(board) do
    # results =
    #   for x <- 4..5, y <- 0..5 do
    #     check_row_left(board, x, y)
    #   end

    # Enum.filter(results, & &1)
  end

  defp count_nils(board, column_index), do: Enum.count(column(board, column_index), &is_nil/1)

  defp column(board, column_index) do
    Enum.reduce(board, [], fn row, acc ->
      [Enum.at(row, column_index) | acc]
    end)
  end

  defp at(board, {x, y}), do: at(board, x, y)

  defp at(board, x, y) do
    board
    |> Enum.at(y)
    |> Enum.at(x)
  end
end
