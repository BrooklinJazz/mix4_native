defmodule Connect4.Games.BoardTest do
  use ExUnit.Case, async: true
  doctest Connect4.Games.Board

  alias Connect4.Games.Board

  test "initial_board/0" do
    assert Board.new() == [
             [nil, nil, nil, nil, nil, nil, nil],
             [nil, nil, nil, nil, nil, nil, nil],
             [nil, nil, nil, nil, nil, nil, nil],
             [nil, nil, nil, nil, nil, nil, nil],
             [nil, nil, nil, nil, nil, nil, nil],
             [nil, nil, nil, nil, nil, nil, nil]
           ]
  end

  describe "drop/2" do
    test "column 1" do
      board = Board.new()

      assert Board.drop(board, 0, :red) ==
               [
                 [nil, nil, nil, nil, nil, nil, nil],
                 [nil, nil, nil, nil, nil, nil, nil],
                 [nil, nil, nil, nil, nil, nil, nil],
                 [nil, nil, nil, nil, nil, nil, nil],
                 [nil, nil, nil, nil, nil, nil, nil],
                 [:red, nil, nil, nil, nil, nil, nil]
               ]
    end

    test "column 6" do
      board = Board.new()

      assert Board.drop(board, 6, :red) == [
               [nil, nil, nil, nil, nil, nil, nil],
               [nil, nil, nil, nil, nil, nil, nil],
               [nil, nil, nil, nil, nil, nil, nil],
               [nil, nil, nil, nil, nil, nil, nil],
               [nil, nil, nil, nil, nil, nil, nil],
               [nil, nil, nil, nil, nil, nil, :red]
             ]
    end

    test "fill column 0" do
      board = Board.new()

      assert board
             |> Board.drop(0, :red)
             |> Board.drop(0, :red)
             |> Board.drop(0, :red)
             |> Board.drop(0, :red)
             |> Board.drop(0, :red)
             |> Board.drop(0, :red) ==
               [
                 [:red, nil, nil, nil, nil, nil, nil],
                 [:red, nil, nil, nil, nil, nil, nil],
                 [:red, nil, nil, nil, nil, nil, nil],
                 [:red, nil, nil, nil, nil, nil, nil],
                 [:red, nil, nil, nil, nil, nil, nil],
                 [:red, nil, nil, nil, nil, nil, nil]
               ]
    end

    test "overfill column 0" do
      board = Board.new()

      assert board
             |> Board.drop(0, :red)
             |> Board.drop(0, :red)
             |> Board.drop(0, :red)
             |> Board.drop(0, :red)
             |> Board.drop(0, :red)
             |> Board.drop(0, :red)
             |> Board.drop(0, :red) == {:error, :column_full}
    end
  end

  describe "winner/1" do
    test "no winner" do
      board = [
        [nil, nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil, nil]
      ]

      assert Board.winner(board) == nil
    end

    test "red column" do
      board = [
        [:red, nil, nil, nil, nil, nil, nil],
        [:red, nil, nil, nil, nil, nil, nil],
        [:red, nil, nil, nil, nil, nil, nil],
        [:red, nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil, nil]
      ]

      assert Board.winner(board) == :red
    end

    test "yellow row" do
      board = [
        [nil, nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil, nil],
        [:yellow, :yellow, :yellow, :yellow, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil, nil]
      ]

      assert Board.winner(board) == :yellow
    end

    test "invalid due to multiple winners" do
      board = [
        [nil, nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil, nil],
        [:red, :red, :red, :red, nil, nil, nil],
        [:yellow, :yellow, :yellow, :yellow, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil, nil]
      ]

      assert_raise RuntimeError, fn ->
        Board.winner(board)
      end
    end
  end

  # Many of these tests are coupled to order when they shouldn't be.
  # However, this makes writing these tests simpler.
  describe "winners/1" do
    test "one column winner" do
      board = [
        [:red, nil, nil, nil, nil, nil, nil],
        [:red, nil, nil, nil, nil, nil, nil],
        [:red, nil, nil, nil, nil, nil, nil],
        [:red, nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil, nil]
      ]

      assert [winner_row] = Board.winners(board)
      assert winner_row == [{0, 3}, {0, 2}, {0, 1}, {0, 0}]
    end

    test "multiple column winners" do
      board = [
        [:red, nil, nil, nil, nil, nil, :yellow],
        [:red, nil, nil, :red, nil, nil, :yellow],
        [:red, :red, nil, :red, nil, nil, :yellow],
        [:red, :red, nil, :red, nil, nil, :yellow],
        [nil, :red, nil, :red, nil, nil, :red],
        [nil, :red, nil, :red, nil, nil, nil]
      ]

      assert Board.winners(board) ==
               [
                 [{0, 3}, {0, 2}, {0, 1}, {0, 0}],
                 [{1, 5}, {1, 4}, {1, 3}, {1, 2}],
                 [{3, 4}, {3, 3}, {3, 2}, {3, 1}],
                 [{3, 5}, {3, 4}, {3, 3}, {3, 2}],
                 [{6, 3}, {6, 2}, {6, 1}, {6, 0}]
               ]
    end

    test "one winning right facing row" do
      board = [
        [nil, nil, nil, :red, :red, :red, :red],
        [nil, nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil, nil]
      ]

      assert [row] = Board.winners(board)
      assert row == [{6, 0}, {5, 0}, {4, 0}, {3, 0}]
    end

    test "one winning left facing row" do
      board = [
        [:red, :red, :red, :red, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil, nil]
      ]

      assert [row] = Board.winners(board)
      assert row == [{3, 0}, {2, 0}, {1, 0}, {0, 0}]
    end

    test "multiple row winners" do
      board = [
        [nil, nil, nil, :red, :red, :red, :red],
        [nil, nil, nil, nil, nil, nil, nil],
        [nil, :red, :red, :red, :red, :red, nil],
        [nil, nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil, nil],
        [:yellow, :yellow, :yellow, :yellow, nil, nil, nil]
      ]

      assert Board.winners(board) == [
               [{3, 5}, {2, 5}, {1, 5}, {0, 5}],
               [{4, 2}, {3, 2}, {2, 2}, {1, 2}],
               [{5, 2}, {4, 2}, {3, 2}, {2, 2}],
               [{6, 0}, {5, 0}, {4, 0}, {3, 0}]
             ]
    end

    test "one diagonal up right winner" do
      board = [
        [nil, nil, nil, :red, nil, nil, nil],
        [nil, nil, :red, nil, nil, nil, nil],
        [nil, :red, nil, nil, nil, nil, nil],
        [:red, nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil, nil]
      ]

      assert [diagonal1] = Board.winners(board)
      assert diagonal1 == [{3, 0}, {2, 1}, {1, 2}, {0, 3}]
    end

    test "multiple diagonal up right winner" do
      board = [
        [nil, nil, nil, :red, nil, :red, nil],
        [nil, nil, :red, nil, :red, nil, nil],
        [nil, :red, nil, :red, nil, nil, :red],
        [:red, nil, :red, nil, nil, :red, nil],
        [nil, :red, nil, nil, :red, nil, nil],
        [nil, nil, nil, :red, nil, nil, nil]
      ]

      assert Board.winners(board) == [
               [{3, 0}, {2, 1}, {1, 2}, {0, 3}],
               [{4, 1}, {3, 2}, {2, 3}, {1, 4}],
               [{5, 0}, {4, 1}, {3, 2}, {2, 3}],
               [{6, 2}, {5, 3}, {4, 4}, {3, 5}]
             ]
    end

    test "one diagonal down right winners" do
      board = [
        [nil, nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil, nil],
        [:red, nil, nil, nil, nil, nil, nil],
        [nil, :red, nil, nil, nil, nil, nil],
        [nil, nil, :red, nil, nil, nil, nil],
        [nil, nil, nil, :red, nil, nil, nil]
      ]

      assert [diagonal1] = Board.winners(board)
      assert diagonal1 == [{3, 5}, {2, 4}, {1, 3}, {0, 2}]
    end

    test "multiple diagonal down right winners" do
      board = [
        [nil, nil, nil, :red, nil, nil, nil],
        [nil, :red, nil, nil, :red, nil, nil],
        [:red, nil, :red, nil, nil, :red, nil],
        [nil, :red, nil, :red, nil, nil, :red],
        [nil, nil, :red, nil, :red, nil, nil],
        [nil, nil, nil, :red, nil, :red, nil]
      ]

      assert Board.winners(board) == [
               [{3, 5}, {2, 4}, {1, 3}, {0, 2}],
               [{4, 4}, {3, 3}, {2, 2}, {1, 1}],
               [{5, 5}, {4, 4}, {3, 3}, {2, 2}],
               [{6, 3}, {5, 2}, {4, 1}, {3, 0}]
             ]
    end

    test "integrate columns, rows, and diagonals" do
      board = [
        [nil, nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil, nil],
        [:red, nil, nil, :red, nil, nil, nil],
        [:red, nil, :red, nil, nil, nil, nil],
        [:red, :red, nil, nil, nil, nil, nil],
        [:red, :red, :red, :red, nil, nil, nil]
      ]

      assert Board.winners(board) == [
               [{3, 5}, {2, 5}, {1, 5}, {0, 5}],
               [{0, 5}, {0, 4}, {0, 3}, {0, 2}],
               [{3, 2}, {2, 3}, {1, 4}, {0, 5}]
             ]
    end

    test "all possible winners" do
      board = [
        [:red, :red, :red, :red, :red, :red, :red],
        [:red, :red, :red, :red, :red, :red, :red],
        [:red, :red, :red, :red, :red, :red, :red],
        [:red, :red, :red, :red, :red, :red, :red],
        [:red, :red, :red, :red, :red, :red, :red],
        [:red, :red, :red, :red, :red, :red, :red]
      ]

      rows = 4 * 6
      columns = 7 * 3
      diagonals = 3 * 4 * 2
      total_win_spots = rows + columns + diagonals

      assert Board.winners(board) |> Enum.count() == total_win_spots
    end
  end

  test "transpose/1" do
    board = [
      [:red, nil, nil, :red, nil, nil, :red],
      [:red, nil, nil, nil, nil, nil, :red],
      [:red, nil, nil, nil, nil, nil, :red],
      [:red, nil, nil, nil, nil, nil, :red],
      [:red, nil, nil, nil, nil, nil, :red],
      [:red, nil, nil, nil, nil, nil, :red]
    ]

    assert Board.transpose(board) == [
             [:red, :red, :red, :red, :red, :red],
             [nil, nil, nil, nil, nil, nil],
             [nil, nil, nil, nil, nil, nil],
             [:red, nil, nil, nil, nil, nil],
             [nil, nil, nil, nil, nil, nil],
             [nil, nil, nil, nil, nil, nil],
             [:red, :red, :red, :red, :red, :red]
           ]
  end
end
