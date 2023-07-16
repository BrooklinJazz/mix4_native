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
    check_columns(board)
  end

  def check_columns(board) do
    results =
      for x <- 0..6, y <- 0..2 do
        check_column(board, x, y)
      end

    Enum.filter(results, & &1)
  end

  def check_column(board, x, y, acc \\ [], count \\ 4)
  def check_column(board, x, y, acc, 0), do: Enum.map(acc, fn {_, x, y} -> {x, y} end)

  def check_column(board, x, y, acc, count) do
    case {acc, at(board, x, y)} do
      {_, nil} ->
        false

      {[], current_cell} ->
        check_column(board, x, y + 1, [{current_cell, x, y} | acc], count - 1)

      {[{same_color, prev_x, prev_y} | _], same_color} ->
        check_column(board, x, y + 1, [{same_color, x, y} | acc], count - 1)

      _ ->
        false
    end
  end

  # def check_rows(board) do
  #   for x <- 3..5, y <- 0..6 do
  #     check_column(board, x, y)
  #   end

  #   Enum.filter(results, & &1)
  # end

  defp count_nils(board, column_index), do: Enum.count(column(board, column_index), &is_nil/1)

  defp column(board, column_index) do
    Enum.reduce(board, [], fn row, acc ->
      [Enum.at(row, column_index) | acc]
    end)
  end

  defp at(board, x, y) do
    board
    |> Enum.at(y)
    |> Enum.at(x)
  end
end
