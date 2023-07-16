defmodule Connect4Test do
  use ExUnit.Case
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

  test "winners/1 _ one winner" do
    board = [
      [:red, nil, nil, nil, nil, nil, nil],
      [:red, nil, nil, nil, nil, nil, nil],
      [:red, nil, nil, nil, nil, nil, nil],
      [:red, nil, nil, nil, nil, nil, nil],
      [nil, nil, nil, nil, nil, nil, nil],
      [nil, nil, nil, nil, nil, nil, nil]
    ]

    assert [winner_row] = Connect4.winners(board)
    assert Enum.sort(winner_row) == Enum.sort([{0, 0}, {0, 1}, {0, 2}, {0, 3}])
  end

  test "check_columns/1 _ one winner" do
    board = [
      [:red, nil, nil, nil, nil, nil, nil],
      [:red, nil, nil, nil, nil, nil, nil],
      [:red, nil, nil, nil, nil, nil, nil],
      [:red, nil, nil, nil, nil, nil, nil],
      [nil, nil, nil, nil, nil, nil, nil],
      [nil, nil, nil, nil, nil, nil, nil]
    ]

    assert [winner_row] = Connect4.check_columns(board)
    # order does not matter
    assert Enum.sort(winner_row) == [{0, 0}, {0, 1}, {0, 2}, {0, 3}]
  end

  test "check_columns/1 _ multiple winners" do
    board = [
      [:red, nil, nil, nil, nil, nil, :yellow],
      [:red, nil, nil, :red, nil, nil, :yellow],
      [:red, :red, nil, :red, nil, nil, :yellow],
      [:red, :red, nil, :red, nil, nil, :yellow],
      [nil, :red, nil, :red, nil, nil, :red],
      [nil, :red, nil, :red, nil, nil, nil]
    ]

    assert Connect4.check_columns(board) ==
             [
               [{0, 3}, {0, 2}, {0, 1}, {0, 0}],
               [{1, 5}, {1, 4}, {1, 3}, {1, 2}],
               [{3, 4}, {3, 3}, {3, 2}, {3, 1}],
               [{3, 5}, {3, 4}, {3, 3}, {3, 2}],
               [{6, 3}, {6, 2}, {6, 1}, {6, 0}]
             ]
  end

  test "check_rows/1 one winner" do
    board = [
      [:red, :red, :red, :red, nil, nil, nil],
      [nil, nil, nil, nil, nil, nil, nil],
      [nil, nil, nil, nil, nil, nil, nil],
      [nil, nil, nil, nil, nil, nil, nil],
      [nil, nil, nil, nil, nil, nil, nil],
      [nil, nil, nil, nil, nil, nil, nil]
    ]

    assert [row] = Connect4.check_rows(board)
    assert row == [{0, 0}, {1, 0}, {2, 0}, {3, 0}]
  end

  @tag :skip
  test "check_rows/1 multiple winners" do
    board = [
      [nil, nil, nil, :red, :red, :red, :red],
      [nil, nil, nil, nil, nil, nil, nil],
      [nil, :red, :red, :red, :red, :red, nil],
      [nil, nil, nil, nil, nil, nil, nil],
      [nil, nil, nil, nil, nil, nil, nil],
      [:yellow, :yellow, :yellow, :yellow, nil, nil, nil]
    ]

    sorted_winners = Connect4.winners(board) |> Enum.sort()
  end

  @tag :skip
  test "diagonal right" do
    [
      [nil, nil, nil, :red, nil, :red, nil],
      [nil, nil, :red, nil, :red, nil, nil],
      [nil, :red, nil, :red, nil, nil, :red],
      [:red, nil, :red, nil, nil, :red, nil],
      [nil, :red, nil, nil, :red, nil, nil],
      [nil, nil, nil, :red, nil, nil, nil]
    ]
  end

  @tag :skip
  test "diagonal left" do
    [
      [nil, :yellow, nil, :red, nil, nil, nil],
      [nil, nil, :yellow, nil, :red, nil, nil],
      [:red, nil, nil, :yellow, nil, :red, nil],
      [nil, :red, nil, nil, :yellow, nil, :red],
      [nil, nil, :red, nil, nil, :yellow, nil],
      [nil, nil, nil, :red, nil, nil, nil]
    ]
  end
end
