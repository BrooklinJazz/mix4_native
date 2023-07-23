defmodule Connect4Test do
  use ExUnit.Case, async: true
  doctest Connect4

  alias Connect4

  test "initial_board/0" do
    assert Connect4.initial_board() == [
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
      board = Connect4.initial_board()

      assert Connect4.drop(board, 0, :red) ==
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
      board = Connect4.initial_board()

      assert Connect4.drop(board, 6, :red) == [
               [nil, nil, nil, nil, nil, nil, nil],
               [nil, nil, nil, nil, nil, nil, nil],
               [nil, nil, nil, nil, nil, nil, nil],
               [nil, nil, nil, nil, nil, nil, nil],
               [nil, nil, nil, nil, nil, nil, nil],
               [nil, nil, nil, nil, nil, nil, :red]
             ]
    end

    test "fill column 0" do
      board = Connect4.initial_board()

      assert board
             |> Connect4.drop(0, :red)
             |> Connect4.drop(0, :red)
             |> Connect4.drop(0, :red)
             |> Connect4.drop(0, :red)
             |> Connect4.drop(0, :red)
             |> Connect4.drop(0, :red) ==
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
      board = Connect4.initial_board()

      assert board
             |> Connect4.drop(0, :red)
             |> Connect4.drop(0, :red)
             |> Connect4.drop(0, :red)
             |> Connect4.drop(0, :red)
             |> Connect4.drop(0, :red)
             |> Connect4.drop(0, :red)
             |> Connect4.drop(0, :red) == {:error, :column_full}
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

      assert Connect4.winner(board) == nil
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

      assert Connect4.winner(board) == :red
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

      assert Connect4.winner(board) == :yellow
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
        Connect4.winner(board)
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

      assert [winner_row] = Connect4.winners(board)
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

      assert Connect4.winners(board) ==
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

      assert [row] = Connect4.winners(board)
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

      assert [row] = Connect4.winners(board)
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

      assert Connect4.winners(board) == [
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

      assert [diagonal1] = Connect4.winners(board)
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

      assert Connect4.winners(board) == [
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

      assert [diagonal1] = Connect4.winners(board)
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

      assert Connect4.winners(board) == [
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

      assert Connect4.winners(board) == [
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

      assert Connect4.winners(board) |> Enum.count() == total_win_spots
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

    assert Connect4.transpose(board) == [
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
