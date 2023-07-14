defmodule Connect4 do
  @moduledoc """
  Connect4 keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """
  @board [
    [nil, nil, nil, nil, nil, nil, nil],
    [nil, nil, nil, nil, nil, nil, nil],
    [nil, nil, nil, nil, nil, nil, nil],
    [nil, nil, nil, nil, nil, nil, nil],
    [nil, nil, nil, nil, nil, nil, nil],
    [nil, nil, nil, nil, nil, nil, nil]
  ]

  def board, do: @board

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

  defp count_nils(board, column_index), do: Enum.count(column(board, column_index), &is_nil/1)

  defp column(board, column_index) do
    Enum.reduce(board, [], fn row, acc ->
      [Enum.at(row, column_index) | acc]
    end)
  end
end

# OTHER ATTEMPTS
# lowest_position =
#   Enum.reduce(board, 0, fn row, acc ->
#     if Enum.at(row, column_index) == nil do
#       acc + 1
#     else
#       acc
#     end
#   end)

# if nil_count == 0 do
#   {:error, :column_full}
# else
# end

# new_column =
#   board
#   |> column(column_index)
#   |> Enum.reduce([], fn
#     nil, {acc, false} -> {[marker | acc], true}
#     each, {acc, true} -> {[each | acc], true}
#   end)
#   |> Enum.reverse()

# List.replace_at(board, )

# board
# |> Enum.reverse()
# |> IO.inspect()
# |> Enum.reduce({[], false}, fn
#   row, {acc, true} ->
#     {[row | acc], true}

#   row, {acc, false} ->
#     if Enum.at(row, column_index) == nil do
#       new_row = List.replace_at(row, column_index, marker)
#       {[new_row | acc], true}
#     else
#       {[row | acc], false}
#     end
# end)
# |> elem(0)
