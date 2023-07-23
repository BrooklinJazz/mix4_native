defmodule Connect4.GameTest do
  use ExUnit.Case
  doctest Connect4.Game
  alias Connect4.Game
  alias Connect4.Player

  test "board/1" do
    player1 = Player.new()
    player2 = Player.new()
    {:ok, pid} = Game.start_link(player1: player1, player2: player2)

    assert Game.board(pid) == [
             [nil, nil, nil, nil, nil, nil, nil],
             [nil, nil, nil, nil, nil, nil, nil],
             [nil, nil, nil, nil, nil, nil, nil],
             [nil, nil, nil, nil, nil, nil, nil],
             [nil, nil, nil, nil, nil, nil, nil],
             [nil, nil, nil, nil, nil, nil, nil]
           ]
  end

  test "game/1" do
    player1 = Player.new()
    player2 = Player.new()
    {:ok, pid} = Game.start_link(player1: player1, player2: player2)
    assert %Game{} = game = Game.game(pid)
    assert game.player1 == player1
    assert game.player2 == player2
    assert game.current_turn == player1
  end

  test "drop/1 drops disc" do
    player1 = Player.new()
    player2 = Player.new()
    {:ok, pid} = Game.start_link(player1: player1, player2: player2)
    assert Game.drop(pid, player1, 0) == :ok

    assert Game.board(pid) == [
             [nil, nil, nil, nil, nil, nil, nil],
             [nil, nil, nil, nil, nil, nil, nil],
             [nil, nil, nil, nil, nil, nil, nil],
             [nil, nil, nil, nil, nil, nil, nil],
             [nil, nil, nil, nil, nil, nil, nil],
             [:red, nil, nil, nil, nil, nil, nil]
           ]

    assert Game.drop(pid, player2, 0) == :ok

    assert Game.board(pid) == [
             [nil, nil, nil, nil, nil, nil, nil],
             [nil, nil, nil, nil, nil, nil, nil],
             [nil, nil, nil, nil, nil, nil, nil],
             [nil, nil, nil, nil, nil, nil, nil],
             [:yellow, nil, nil, nil, nil, nil, nil],
             [:red, nil, nil, nil, nil, nil, nil]
           ]
  end

  test "drop/1 only drops disc for current player" do
    player1 = Player.new()
    player2 = Player.new()

    {:ok, pid} = Game.start_link(player1: player1, player2: player2)
    assert Game.drop(pid, player2, 0) == :error

    assert Game.board(pid) == [
             [nil, nil, nil, nil, nil, nil, nil],
             [nil, nil, nil, nil, nil, nil, nil],
             [nil, nil, nil, nil, nil, nil, nil],
             [nil, nil, nil, nil, nil, nil, nil],
             [nil, nil, nil, nil, nil, nil, nil],
             [nil, nil, nil, nil, nil, nil, nil]
           ]
  end

  test "winner/1 returns winning player" do
    player1 = Player.new()
    player2 = Player.new()
    {:ok, pid} = Game.start_link(player1: player1, player2: player2)
    assert Game.drop(pid, player1, 0) == :ok
    assert Game.drop(pid, player2, 1) == :ok
    assert Game.drop(pid, player1, 0) == :ok
    assert Game.drop(pid, player2, 1) == :ok
    assert Game.drop(pid, player1, 0) == :ok
    assert Game.drop(pid, player2, 1) == :ok
    assert Game.drop(pid, player1, 0) == :ok

    assert Game.winner(pid) == player1
  end
end
