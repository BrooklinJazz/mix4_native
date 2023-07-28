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

  test "join/2 puts two players in a game" do
    playera = Player.new(id: "a", name: "playera")
    playerb = Player.new(id: "b", name: "playerb")

    games = Games.new()
    {:enqueued, games} = Games.join(games, playera)
    {:game_started, games} = Games.join(games, playerb)

    assert %Game{} = game = Games.find_game(games, playera)
    assert Game.player1(game) in [playera, playerb]
    assert Game.player2(game) in [playera, playerb]
  end

  test "join/2 player cannot join a game when they are already in a game" do
    playera = Player.new(id: "a", name: "playera")
    playerb = Player.new(id: "b", name: "playerb")
    games = Games.new()

    {:enqueued, games} = Games.join(games, playera)
    {:game_started, games} = Games.join(games, playerb)
    assert {:ignored, _games} = Games.join(games, playera)
    assert {:ignored, _games} = Games.join(games, playerb)
  end

  test "join/2 end game and add player to queue if there is already a winner" do
    playera = Player.new(id: "a", name: "playera")
    playerb = Player.new(id: "b", name: "playerb")
    games = Games.new()

    {:enqueued, games} = Games.join(games, playera)
    {:game_started, games} = Games.join(games, playerb)
    game = Games.find_game(games, playera)
    games = Games.update(games, %Game{game | winner: playera})

    {:enqueued, games} = Games.join(games, playera)
    refute Games.find_game(games, playerb)
    refute Games.find_game(games, playerb)

    {:game_started, games} = Games.join(games, playerb)
    assert Games.find_game(games, playerb)
    assert Games.find_game(games, playerb)
  end

  test "update/2" do
    playera = Player.new(id: "a", name: "playera")
    playerb = Player.new(id: "b", name: "playerb")

    games = Games.new()
    {:enqueued, games} = Games.join(games, playera)
    {:game_started, games} = Games.join(games, playerb)

    game = Games.find_game(games, playera)
    updated_game = Game.drop(game, Game.player1(game), 0)
    %Games{} = games = Games.update(games, updated_game)
    assert Games.find_game(games, playera) == updated_game
  end

  test "waiting?/2" do
    playera = Player.new(id: "a", name: "playera")
    playerb = Player.new(id: "b", name: "playerb")

    games = Games.new()
    refute Games.waiting?(games, playera)
    refute Games.waiting?(games, playerb)
    {:enqueued, games} = Games.join(games, playera)
    assert Games.waiting?(games, playera)
    {:game_started, games} = Games.join(games, playerb)
    refute Games.waiting?(games, playera)
    refute Games.waiting?(games, playerb)
  end

  test "quit/2" do
    playera = Player.new(id: "a", name: "playera")
    playerb = Player.new(id: "b", name: "playerb")

    games = Games.new()
    {:enqueued, games} = Games.join(games, playera)
    {:game_started, games} = Games.join(games, playera)

    assert {:ok, games} = Games.quit(games, playera)

    assert Games.find_game(games, playera) == nil
    assert Games.find_game(games, playerb) == nil
  end
end
