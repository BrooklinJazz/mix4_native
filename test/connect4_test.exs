defmodule Connect4Test do
  use ExUnit.Case
  doctest Connect4
  alias Connect4

  test "initial_board" do
    assert Connect4.board() == [
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
      board = Connect4.board()

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
      board = Connect4.board()

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
      board = Connect4.board()

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
      board = Connect4.board()

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

  # describe "winners/1" do
  #   test "vertical" do
  #     board = [
  #       [nil, nil, nil, nil, nil, nil, :yellow],
  #       [nil, nil, nil, :red, nil, nil, :yellow],
  #       [nil, :red, nil, :red, nil, nil, :yellow],
  #       [nil, :red, nil, :red, nil, nil, :yellow],
  #       [nil, :red, nil, :red, nil, nil, nil],
  #       [nil, :red, nil, nil, nil, nil, nil]
  #     ]

  #     sorted_winners = Connect4.winners(board) |> Enum.sort()

  #     expected_sorted_winners =
  #       Enum.sort([
  #         [{1, 0}, {1, 1}, {1, 2}, {1, 3}],
  #         [{3, 1}, {3, 2}, {3, 3}, {3, 4}],
  #         [{6, 2}, {6, 3}, {6, 4}, {6, 5}]
  #       ])

  #     assert sorted_winners == expected_sorted_winners
  #   end

  #   @tag :skip
  #   test "horizontal" do
  #     board = [
  #       [nil, nil, nil, :red, :red, :red, :red],
  #       [nil, nil, nil, nil, nil, nil, nil],
  #       [nil, :red, :red, :red, :red, :red, nil],
  #       [nil, nil, nil, nil, nil, nil, nil],
  #       [nil, nil, nil, nil, nil, nil, nil],
  #       [:yellow, :yellow, :yellow, :yellow, nil, nil, nil]
  #     ]

  #     board = [
  #       [nil, nil, nil, nil, nil, nil, :yellow],
  #       [nil, nil, nil, :red, nil, nil, :yellow],
  #       [nil, :red, nil, :red, nil, nil, :yellow],
  #       [nil, :red, nil, :red, nil, nil, :yellow],
  #       [nil, :red, nil, :red, nil, nil, nil],
  #       [nil, :red, nil, nil, nil, nil, nil]
  #     ]

  #     sorted_winners = Connect4.winners(board) |> Enum.sort()
  #   end

  #   @tag :skip
  #   test "diagonal right" do
  #     [
  #       [nil, nil, nil, :red, nil, :red, nil],
  #       [nil, nil, :red, nil, :red, nil, nil],
  #       [nil, :red, nil, :red, nil, nil, :red],
  #       [:red, nil, :red, nil, nil, :red, nil],
  #       [nil, :red, nil, nil, :red, nil, nil],
  #       [nil, nil, nil, :red, nil, nil, nil]
  #     ]
  #   end

  #   @tag :skip
  #   test "diagonal left" do
  #     [
  #       [nil, :yellow, nil, :red, nil, nil, nil],
  #       [nil, nil, :yellow, nil, :red, nil, nil],
  #       [:red, nil, nil, :yellow, nil, :red, nil],
  #       [nil, :red, nil, nil, :yellow, nil, :red],
  #       [nil, nil, :red, nil, nil, :yellow, nil],
  #       [nil, nil, nil, :red, nil, nil, nil]
  #     ]
  #   end
  # end
end
