defmodule Connect4.GamesServerTest do
  use ExUnit.Case
  doctest Connect4.GamesServer
  alias Connect4.GamesServer
  alias Connect4.Games.Game
  alias Connect4.Games.Player

  test "start_link/1" do
    {:ok, pid} = GamesServer.start_link(name: nil)
    assert pid
  end

  test "join/2 adds two players to game" do
    playera = Player.new(id: "a", name: "playera")
    playerb = Player.new(id: "b", name: "playerb")
    {:ok, pid} = GamesServer.start_link(name: nil)

    assert GamesServer.join(pid, playera) == :ok
    assert GamesServer.join(pid, playerb) == :ok

    assert %Game{} = GamesServer.find_game(pid, playera)
  end

  test "join/2 refuse players in existing game" do
    playera = Player.new(id: "a", name: "playera")
    playerb = Player.new(id: "b", name: "playerb")
    {:ok, pid} = GamesServer.start_link(name: nil)

    assert GamesServer.join(pid, playera) == :ok
    assert GamesServer.join(pid, playerb) == :ok

    assert GamesServer.join(pid, playera) == :error
    assert GamesServer.join(pid, playerb) == :error
  end

  test "join/2 broadcast message to subscribers of game start" do
    playera = Player.new(id: "a", name: "playera")
    playerb = Player.new(id: "b", name: "playerb")
    {:ok, pid} = GamesServer.start_link(name: nil)

    Phoenix.PubSub.subscribe(Connect4.PubSub, "player:#{playera.id}")
    Phoenix.PubSub.subscribe(Connect4.PubSub, "player:#{playerb.id}")

    assert GamesServer.join(pid, playera) == :ok
    assert GamesServer.join(pid, playerb) == :ok

    assert_receive {:game_started, %Game{}}
    assert_receive {:game_started, %Game{}}
  end

  test "update/2 updates game" do
    playera = Player.new(id: "a", name: "playera")
    playerb = Player.new(id: "b", name: "playerb")
    {:ok, pid} = GamesServer.start_link(name: nil)

    GamesServer.join(pid, playera)
    GamesServer.join(pid, playerb)

    game = GamesServer.find_game(pid, playera)
    updated_game = Game.drop(game, Game.player1(game), 0)

    GamesServer.update(pid, updated_game)
    assert GamesServer.find_game(pid, playera) == updated_game
  end

  test "update/2 broadcast updated game to subscribers" do
    playera = Player.new(id: "a", name: "playera")
    playerb = Player.new(id: "b", name: "playerb")
    {:ok, pid} = GamesServer.start_link(name: nil)

    GamesServer.join(pid, playera)
    GamesServer.join(pid, playerb)

    game = GamesServer.find_game(pid, playera)

    Phoenix.PubSub.subscribe(Connect4.PubSub, "game:#{game.id}")

    updated_game = Game.drop(game, Game.player1(game), 0)
    GamesServer.update(pid, updated_game)

    assert_receive {:game_updated, ^updated_game}
  end
end