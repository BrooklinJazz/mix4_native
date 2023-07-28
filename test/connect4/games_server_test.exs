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

  test "drop/4" do
    playera = Player.new(id: "a", name: "playera")
    playerb = Player.new(id: "b", name: "playerb")
    {:ok, pid} = GamesServer.start_link(name: nil)

    GamesServer.join(pid, playera)
    GamesServer.join(pid, playerb)

    game = GamesServer.find_game_by_player(pid, playera)

    Phoenix.PubSub.subscribe(Connect4.PubSub, "game:#{game.id}")

    expected_game = Game.drop(game, Game.player1(game), 0)
    GamesServer.drop(pid, game.id, Game.player1(game), 0)

    assert_receive {:game_updated, ^expected_game}
  end

  test "drop/4 with invalid game id" do
    playera = Player.new(id: "a", name: "playera")
    {:ok, pid} = GamesServer.start_link(name: nil)

    assert GamesServer.drop(pid, "some invalid id", playera, 0) == :error
    refute_receive {:disc_dropped, _turn_timer, _updated_game}
  end

  test "join/2 adds two players to game" do
    playera = Player.new(id: "a", name: "playera")
    playerb = Player.new(id: "b", name: "playerb")
    {:ok, pid} = GamesServer.start_link(name: nil)

    assert GamesServer.join(pid, playera) == :ok
    assert GamesServer.join(pid, playerb) == :ok

    assert %Game{} = GamesServer.find_game_by_player(pid, playera)
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

  test "join/2 remove game after player wins" do
    playera = Player.new(id: "a", name: "playera")
    playerb = Player.new(id: "b", name: "playerb")
    {:ok, pid} = GamesServer.start_link(name: nil)

    assert GamesServer.join(pid, playera) == :ok
    assert GamesServer.join(pid, playerb) == :ok

    game = GamesServer.find_game_by_player(pid, playera)
    GamesServer.update(pid, %Game{game | winner: playera})

    GamesServer.join(pid, playera)
    refute GamesServer.find_game_by_player(pid, playera)
    refute GamesServer.find_game_by_player(pid, playerb)

    GamesServer.join(pid, playerb)
    assert GamesServer.find_game_by_player(pid, playera)
    assert GamesServer.find_game_by_player(pid, playerb)
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

    game = GamesServer.find_game_by_player(pid, playera)
    updated_game = Game.drop(game, Game.player1(game), 0)

    GamesServer.update(pid, updated_game)
    assert GamesServer.find_game_by_player(pid, playera) == updated_game
  end

  test "update/2 broadcast updated game to subscribers" do
    playera = Player.new(id: "a", name: "playera")
    playerb = Player.new(id: "b", name: "playerb")
    {:ok, pid} = GamesServer.start_link(name: nil)

    GamesServer.join(pid, playera)
    GamesServer.join(pid, playerb)

    game = GamesServer.find_game_by_player(pid, playera)

    Phoenix.PubSub.subscribe(Connect4.PubSub, "game:#{game.id}")

    updated_game = Game.drop(game, Game.player1(game), 0)
    GamesServer.update(pid, updated_game)

    assert_receive {:game_updated, ^updated_game}
  end

  test "waiting?/2" do
    playera = Player.new(id: "a", name: "playera")
    playerb = Player.new(id: "b", name: "playerb")
    {:ok, pid} = GamesServer.start_link(name: nil)

    refute GamesServer.waiting?(pid, playera)
    refute GamesServer.waiting?(pid, playerb)

    GamesServer.join(pid, playera)
    assert GamesServer.waiting?(pid, playera)

    GamesServer.join(pid, playerb)
    refute GamesServer.waiting?(pid, playera)
    refute GamesServer.waiting?(pid, playerb)
  end

  test "quit/3" do
    playera = Player.new(id: "a", name: "playera")
    playerb = Player.new(id: "b", name: "playerb")
    {:ok, pid} = GamesServer.start_link(name: nil)

    GamesServer.join(pid, playera)
    GamesServer.join(pid, playerb)

    GamesServer.quit(pid, playera)
    refute GamesServer.find_game_by_player(pid, playera)
    refute GamesServer.find_game_by_player(pid, playerb)
  end

  test "quit/2 broadcast quit game to subscribers" do
    playera = Player.new(id: "a", name: "playera")
    playerb = Player.new(id: "b", name: "playerb")
    {:ok, pid} = GamesServer.start_link(name: nil)

    GamesServer.join(pid, playera)
    GamesServer.join(pid, playerb)

    game = GamesServer.find_game_by_player(pid, playera)

    Phoenix.PubSub.subscribe(Connect4.PubSub, "game:#{game.id}")

    GamesServer.quit(pid, playera)
    assert_receive {:game_quit, ^playera}
  end
end
