defmodule Connect4.Games.GameTest do
  use ExUnit.Case
  doctest Connect4.Games.Game
  alias Connect4.Games.Board
  alias Connect4.Games.Game
  alias Connect4.Games.Player

  @turn_duration 30

  test "board/1" do
    playera = Player.new(id: "a")
    playerb = Player.new(id: "b")
    game = Game.new(playera, playerb)
    assert Game.board(game) == Board.new()
  end

  test "current_turn/1" do
    playera = Player.new(id: "a")
    playerb = Player.new(id: "b")
    game = Game.new(playera, playerb)
    assert Game.current_turn(game) == Game.player1(game)
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

  test "drop/3 renews turn end timer" do
    playera = Player.new(id: "a")
    playerb = Player.new(id: "b")
    game = Game.new(playera, playerb)
    game = Game.drop(game, Game.player1(game), 0)

    assert Game.turn_end_time(game) ==
             DateTime.add(DateTime.utc_now(:second), @turn_duration, :second)
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

  test "finished?/1" do
    game = %Game{winner: Player.new(id: "a")}
    assert Game.finished?(game)
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

  test "new/2 start game randomly selects player1 and player2" do
    playera = Player.new(id: "a")
    playerb = Player.new(id: "b")
    assert %Game{} = game = Game.new(playera, playerb)
    assert game.id
    assert game.player1 in [playera, playerb]
    assert game.player2 in [playera, playerb]
    assert game.board == Board.new()
  end

  test "next_player/1" do
    playera = Player.new(id: "a")
    playerb = Player.new(id: "b")
    game = Game.new(playera, playerb)
    assert Game.next_player(game) == Game.player2(game)
  end

  test "opponent/2" do
    playera = Player.new(id: "a")
    playerb = Player.new(id: "b")
    game = Game.new(playera, playerb)

    assert Game.opponent(game, playera) == playerb
    assert Game.opponent(game, playerb) == playera
  end

  test "player#/1" do
    playera = Player.new(id: "a")
    playerb = Player.new(id: "b")
    game = Game.new(playera, playerb)
    assert Game.player1(game) in [playera, playerb]
    assert Game.player2(game) in [playera, playerb]
    assert Game.player1(game) != Game.player2(game)
  end

  test "run_out_of_time/1 current player" do
    playera = Player.new(id: "a")
    playerb = Player.new(id: "b")
    game = Game.new(playera, playerb)

    player1 = Game.player1(game)
    player2 = Game.player2(game)
    assert Game.current_turn(game) == player1
    game = Game.run_out_of_time(game, player1)
    assert Game.current_turn(game) == player2

    assert Game.turn_end_time(game) ==
             DateTime.add(DateTime.utc_now(:second), @turn_duration, :second)
  end

  test "run_out_of_time/1 not current player" do
    playera = Player.new(id: "a")
    playerb = Player.new(id: "b")
    game = Game.new(playera, playerb)

    player1 = Game.player1(game)
    player2 = Game.player2(game)
    assert Game.current_turn(game) == player1
    game = Game.run_out_of_time(game, player2)
    assert Game.current_turn(game) == player1
  end

  test "turn_end_time/1" do
    playera = Player.new(id: "a")
    playerb = Player.new(id: "b")
    game = Game.new(playera, playerb)

    assert Game.turn_end_time(game) ==
             DateTime.add(DateTime.utc_now(:second), @turn_duration, :second)
  end
end
