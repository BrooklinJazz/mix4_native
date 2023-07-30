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

    GamesServer.join_queue(pid, playera)
    GamesServer.join_queue(pid, playerb)

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

  test "incoming_requests/3" do
    playera = Player.new(id: "a", name: "playera")
    playerb = Player.new(id: "b", name: "playerb")
    playerc = Player.new(id: "c", name: "playerc")

    {:ok, pid} = GamesServer.start_link(name: nil)
    GamesServer.request(pid, playerb, playera)
    GamesServer.request(pid, playerc, playera)

    actual = GamesServer.incoming_requests(pid, playera)
    expected = [playerb, playerc]

    assert Enum.sort(actual) == Enum.sort(expected)
  end

  test "join_queue/2 adds two players to game" do
    playera = Player.new(id: "a", name: "playera")
    playerb = Player.new(id: "b", name: "playerb")
    {:ok, pid} = GamesServer.start_link(name: nil)

    assert GamesServer.join_queue(pid, playera) == :ok
    assert GamesServer.join_queue(pid, playerb) == :ok

    assert %Game{} = GamesServer.find_game_by_player(pid, playera)
    assert %Game{} = GamesServer.find_game_by_player(pid, playerb)
  end

  test "join_queue/2 refuse players in existing game" do
    playera = Player.new(id: "a", name: "playera")
    playerb = Player.new(id: "b", name: "playerb")
    {:ok, pid} = GamesServer.start_link(name: nil)

    assert GamesServer.join_queue(pid, playera) == :ok
    assert GamesServer.join_queue(pid, playerb) == :ok

    assert GamesServer.join_queue(pid, playera) == :error
    assert GamesServer.join_queue(pid, playerb) == :error
  end

  test "join_queue/2 remove game after player wins" do
    playera = Player.new(id: "a", name: "playera")
    playerb = Player.new(id: "b", name: "playerb")
    {:ok, pid} = GamesServer.start_link(name: nil)

    assert GamesServer.join_queue(pid, playera) == :ok
    assert GamesServer.join_queue(pid, playerb) == :ok

    game = GamesServer.find_game_by_player(pid, playera)
    GamesServer.update(pid, %Game{game | winner: playera})

    GamesServer.join_queue(pid, playera)
    refute GamesServer.find_game_by_player(pid, playera)
    refute GamesServer.find_game_by_player(pid, playerb)

    GamesServer.join_queue(pid, playerb)
    assert GamesServer.find_game_by_player(pid, playera)
    assert GamesServer.find_game_by_player(pid, playerb)
  end

  test "join_queue/2 broadcast message to subscribers of game start" do
    playera = Player.new(id: "a", name: "playera")
    playerb = Player.new(id: "b", name: "playerb")
    {:ok, pid} = GamesServer.start_link(name: nil)

    Phoenix.PubSub.subscribe(Connect4.PubSub, "player:#{playera.id}")
    Phoenix.PubSub.subscribe(Connect4.PubSub, "player:#{playerb.id}")

    assert GamesServer.join_queue(pid, playera) == :ok
    assert GamesServer.join_queue(pid, playerb) == :ok

    assert_receive {:game_started, %Game{}}
    assert_receive {:game_started, %Game{}}
  end

  test "leave_queue/2" do
    playera = Player.new(id: "a", name: "playera")
    {:ok, pid} = GamesServer.start_link(name: nil)
    GamesServer.join_queue(pid, playera)

    GamesServer.leave_queue(pid, playera)
    refute GamesServer.waiting?(pid, playera)
  end

  test "outgoing_requests/3" do
    playera = Player.new(id: "a", name: "playera")
    playerb = Player.new(id: "b", name: "playerb")
    playerc = Player.new(id: "c", name: "playerc")

    {:ok, pid} = GamesServer.start_link(name: nil)
    GamesServer.request(pid, playera, playerb)
    GamesServer.request(pid, playera, playerc)

    actual = GamesServer.outgoing_requests(pid, playera)
    expected = [playerb, playerc]
    assert Enum.sort(actual) == Enum.sort(expected)
  end

  test "update/2 updates game" do
    playera = Player.new(id: "a", name: "playera")
    playerb = Player.new(id: "b", name: "playerb")
    {:ok, pid} = GamesServer.start_link(name: nil)

    GamesServer.join_queue(pid, playera)
    GamesServer.join_queue(pid, playerb)

    game = GamesServer.find_game_by_player(pid, playera)
    updated_game = Game.drop(game, Game.player1(game), 0)

    GamesServer.update(pid, updated_game)
    assert GamesServer.find_game_by_player(pid, playera) == updated_game
  end

  test "update/2 broadcast updated game to subscribers" do
    playera = Player.new(id: "a", name: "playera")
    playerb = Player.new(id: "b", name: "playerb")
    {:ok, pid} = GamesServer.start_link(name: nil)

    GamesServer.join_queue(pid, playera)
    GamesServer.join_queue(pid, playerb)

    game = GamesServer.find_game_by_player(pid, playera)

    Phoenix.PubSub.subscribe(Connect4.PubSub, "game:#{game.id}")

    updated_game = Game.drop(game, Game.player1(game), 0)
    GamesServer.update(pid, updated_game)

    assert_receive {:game_updated, ^updated_game}
  end

  test "quit/3" do
    playera = Player.new(id: "a", name: "playera")
    playerb = Player.new(id: "b", name: "playerb")
    {:ok, pid} = GamesServer.start_link(name: nil)

    GamesServer.join_queue(pid, playera)
    GamesServer.join_queue(pid, playerb)

    GamesServer.quit(pid, playera)
    refute GamesServer.find_game_by_player(pid, playera)
    refute GamesServer.find_game_by_player(pid, playerb)
  end

  test "quit/2 broadcast quit game to subscribers" do
    playera = Player.new(id: "a", name: "playera")
    playerb = Player.new(id: "b", name: "playerb")
    {:ok, pid} = GamesServer.start_link(name: nil)

    GamesServer.join_queue(pid, playera)
    GamesServer.join_queue(pid, playerb)

    game = GamesServer.find_game_by_player(pid, playera)

    Phoenix.PubSub.subscribe(Connect4.PubSub, "game:#{game.id}")

    GamesServer.quit(pid, playera)
    assert_receive {:game_quit, ^playera}
  end

  test "request/3 two players request" do
    playera = Player.new(id: "a", name: "playera")
    playerb = Player.new(id: "b", name: "playerb")
    {:ok, pid} = GamesServer.start_link(name: nil)

    Phoenix.PubSub.subscribe(Connect4.PubSub, "player:#{playera.id}")
    Phoenix.PubSub.subscribe(Connect4.PubSub, "player:#{playerb.id}")

    GamesServer.request(pid, playera, playerb)

    GamesServer.request(pid, playerb, playera)

    assert_receive {:game_started, %Game{}}
    assert_receive {:game_started, %Game{}}

    playera_game = GamesServer.find_game_by_player(pid, playera)
    playerb_game = GamesServer.find_game_by_player(pid, playera)
    assert playera_game
    assert playerb_game
    assert playera_game == playerb_game
  end

  test "request/3 multiple requests _ removes existing requests" do
    playera = Player.new(id: "a", name: "playera")
    playerb = Player.new(id: "b", name: "playerb")
    playerc = Player.new(id: "c", name: "playerc")
    {:ok, pid} = GamesServer.start_link(name: nil)

    GamesServer.request(pid, playera, playerb)
    GamesServer.request(pid, playera, playerc)
    GamesServer.request(pid, playerb, playera)
    refute GamesServer.find_game_by_player(playerb)
  end

  test "request/3 player already in game" do
    playera = Player.new(id: "a", name: "playera")
    playerb = Player.new(id: "b", name: "playerb")
    {:ok, pid} = GamesServer.start_link(name: nil)
    :ok = GamesServer.join_queue(pid, playera)
    :ok = GamesServer.join_queue(pid, playerb)
    assert GamesServer.request(pid, playera, playerb) == :error
  end

  test "request/3 broadcast request to subscribers" do
    playera = Player.new(id: "a", name: "playera")
    playerb = Player.new(id: "b", name: "playerb")
    {:ok, pid} = GamesServer.start_link(name: nil)
    Phoenix.PubSub.subscribe(Connect4.PubSub, "player:#{playera.id}")
    assert GamesServer.request(pid, playerb, playera)
    assert_receive {:game_requested, ^playerb}
  end

  test "waiting?/2" do
    playera = Player.new(id: "a", name: "playera")
    playerb = Player.new(id: "b", name: "playerb")
    {:ok, pid} = GamesServer.start_link(name: nil)

    refute GamesServer.waiting?(pid, playera)
    refute GamesServer.waiting?(pid, playerb)

    GamesServer.join_queue(pid, playera)
    assert GamesServer.waiting?(pid, playera)

    GamesServer.join_queue(pid, playerb)
    refute GamesServer.waiting?(pid, playera)
    refute GamesServer.waiting?(pid, playerb)
  end
end
