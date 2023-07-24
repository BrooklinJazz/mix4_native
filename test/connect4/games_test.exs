defmodule Connect4.GamesTest do
  use ExUnit.Case
  doctest Connect4.Games
  alias Connect4.Games
  alias Connect4.Games.Game
  alias Connect4.Games.Player

  test "new/0" do
    assert %Games{queue: [], active_games: %{}} = Games.new()
  end

  test "find_game/2 no game exists" do
    games = Games.new()
    assert Games.find_game(games, Player.new(id: "a")) == nil
  end

  test "find_game/2 find for player 1 _ game exists" do
    player = Player.new(id: "a")
    games = %Games{active_games: %{"some key" => %Game{player1: player}}}
    assert %Game{} = Games.find_game(games, player)
  end

  test "find_game/2 find for player 2 _ game exists" do
    player = Player.new(id: "a")
    games = %Games{active_games: %{"some key" => %Game{player2: player}}}
    assert %Game{} = Games.find_game(games, player)
  end

  test "join/2 adds player to queue" do
    player = Player.new(id: "a", name: "playera")
    games = Games.new() |> Games.join(player)
    assert Games.queue(games) == [player]
  end

  test "join/2 puts two players in a game" do
    playera = Player.new(id: "a", name: "playera")
    playerb = Player.new(id: "b", name: "playerb")

    games = Games.new() |> Games.join(playera) |> Games.join(playerb)

    assert %Game{} = game = Games.find_game(games, playera)
    assert Game.player1(game) in [playera, playerb]
    assert Game.player2(game) in [playera, playerb]
  end

  test "update/2" do
    playera = Player.new(id: "a", name: "playera")
    playerb = Player.new(id: "b", name: "playerb")

    games = Games.new() |> Games.join(playera) |> Games.join(playerb)
    game = Games.find_game(games, playera)
    updated_game = Game.drop(game, Game.player1(game), 0)
    %Games{} = games = Games.update(games, updated_game)
    assert Games.find_game(games, playera) == updated_game
  end
end
