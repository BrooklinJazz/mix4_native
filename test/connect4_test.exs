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
end
