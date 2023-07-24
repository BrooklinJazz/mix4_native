defmodule Connect4.Games.GameTest do
  use ExUnit.Case
  doctest Connect4.Games.Game
  alias Connect4.Games.Board
  alias Connect4.Games.Game
  alias Connect4.Games.Player

  test "new/2 start game randomly selects player1 and player2" do
    playera = Player.new(id: "a")
    playerb = Player.new(id: "b")
    assert %Game{} = game = Game.new(playera, playerb)
    assert game.id
    assert game.player1 in [playera, playerb]
    assert game.player2 in [playera, playerb]
    assert game.board == Board.new()
  end

  test "board/1" do
    playera = Player.new(id: "a")
    playerb = Player.new(id: "b")
    game = Game.new(playera, playerb)
    assert Game.board(game) == Board.new()
  end

  test "player#/1" do
    playera = Player.new(id: "a")
    playerb = Player.new(id: "b")
    game = Game.new(playera, playerb)
    assert Game.player1(game) in [playera, playerb]
    assert Game.player2(game) in [playera, playerb]
    assert Game.player1(game) != Game.player2(game)
  end

  test "marker/2 player1 is red" do
    playera = Player.new(id: "a")
    playerb = Player.new(id: "b")
    game = Game.new(playera, playerb)

    player1 = Game.player1(game)
    player2 = Game.player2(game)
    assert Game.marker(game, player1) == :red
    assert Game.marker(game, player2) == :yellow
  end

  test "drop/3 drop player1 marker" do
    playera = Player.new(id: "a")
    playerb = Player.new(id: "b")
    game = Game.new(playera, playerb)
    player1 = Game.player1(game)

    assert game |> Game.drop(player1, 0) |> Game.board() == [
             [nil, nil, nil, nil, nil, nil, nil],
             [nil, nil, nil, nil, nil, nil, nil],
             [nil, nil, nil, nil, nil, nil, nil],
             [nil, nil, nil, nil, nil, nil, nil],
             [nil, nil, nil, nil, nil, nil, nil],
             [:red, nil, nil, nil, nil, nil, nil]
           ]
  end

  test "drop/3 drop player2 marker" do
    playera = Player.new(id: "a")
    playerb = Player.new(id: "b")
    game = Game.new(playera, playerb)
    player1 = Game.player1(game)
    player2 = Game.player2(game)

    assert game |> Game.drop(player1, 0) |> Game.drop(player2, 0) |> Game.board() == [
             [nil, nil, nil, nil, nil, nil, nil],
             [nil, nil, nil, nil, nil, nil, nil],
             [nil, nil, nil, nil, nil, nil, nil],
             [nil, nil, nil, nil, nil, nil, nil],
             [:yellow, nil, nil, nil, nil, nil, nil],
             [:red, nil, nil, nil, nil, nil, nil]
           ]
  end

  test "drop/3 ignore player when it is not their turn" do
    playera = Player.new(id: "a")
    playerb = Player.new(id: "b")
    game = Game.new(playera, playerb)
    player2 = Game.player2(game)

    assert game |> Game.drop(player2, 0) |> Game.board() == [
             [nil, nil, nil, nil, nil, nil, nil],
             [nil, nil, nil, nil, nil, nil, nil],
             [nil, nil, nil, nil, nil, nil, nil],
             [nil, nil, nil, nil, nil, nil, nil],
             [nil, nil, nil, nil, nil, nil, nil],
             [nil, nil, nil, nil, nil, nil, nil]
           ]
  end

  test "drop/3 player1 wins" do
    playera = Player.new(id: "a")
    playerb = Player.new(id: "b")
    game = Game.new(playera, playerb)
    player1 = Game.player1(game)
    player2 = Game.player2(game)

    assert game
           |> Game.drop(player1, 0)
           |> Game.drop(player2, 1)
           |> Game.drop(player1, 0)
           |> Game.drop(player2, 1)
           |> Game.drop(player1, 0)
           |> Game.drop(player2, 1)
           |> Game.drop(player1, 0)
           |> Game.winner() == player1
  end

  test "current_player/1" do
    playera = Player.new(id: "a")
    playerb = Player.new(id: "b")
    game = Game.new(playera, playerb)
    assert Game.current_player(game) == Game.player1(game)
  end

  test "next_player/1" do
    playera = Player.new(id: "a")
    playerb = Player.new(id: "b")
    game = Game.new(playera, playerb)
    assert Game.next_player(game) == Game.player2(game)
  end
end
