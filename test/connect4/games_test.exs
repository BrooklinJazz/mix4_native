defmodule Connect4.GamesTest do
  use ExUnit.Case
  doctest Connect4.Games
  alias Connect4.Games
  alias Connect4.Games.Game
  alias Connect4.Games.Player

  test "new/0" do
    assert %Games{queue: [], active_games: %{}} = Games.new()
  end

  test "find_game_by_id/2" do
    game = %Game{id: "some id"}
    games = %Games{active_games: %{game.id => game}}
    assert Games.find_game_by_id(games, game.id) == game
  end

  test "find_game_by_id/2 no game exists" do
    refute Games.find_game_by_id(Games.new(), "some non existent id")
  end

  test "find_game_by_player/2 no game exists" do
    games = Games.new()
    assert Games.find_game_by_player(games, Player.new(id: "a")) == nil
  end

  test "find_game_by_player/2" do
    playera = Player.new(id: "a")
    playerb = Player.new(id: "a")
    game = Game.new(playera, playerb)
    games = %Games{active_games: %{"some key" => game}}

    assert Games.find_game_by_player(games, playera) == game
    assert Games.find_game_by_player(games, playerb) == game
  end

  test "incoming_requests/2" do
    playera = Player.new(id: "a")
    playerb = Player.new(id: "b")
    playerc = Player.new(id: "c")

    games = Games.new()
    {:requested, games} = Games.request(games, playerb, playera)
    {:requested, games} = Games.request(games, playerc, playera)

    actual = Games.incoming_requests(games, playera)
    expected = [playerb, playerc]

    assert Enum.sort(actual) == Enum.sort(expected)
  end

  test "join_queue/2 puts two players in a game" do
    playera = Player.new(id: "a", name: "playera")
    playerb = Player.new(id: "b", name: "playerb")

    games = Games.new()
    {:enqueued, games} = Games.join_queue(games, playera)
    {:game_started, games} = Games.join_queue(games, playerb)

    assert %Game{} = game = Games.find_game_by_player(games, playera)
    assert Game.player1(game) in [playera, playerb]
    assert Game.player2(game) in [playera, playerb]
  end

  test "join_queue/2 player cannot join a game when they are already in a game" do
    playera = Player.new(id: "a", name: "playera")
    playerb = Player.new(id: "b", name: "playerb")
    games = Games.new()

    {:enqueued, games} = Games.join_queue(games, playera)
    {:game_started, games} = Games.join_queue(games, playerb)
    assert {:ignored, _games} = Games.join_queue(games, playera)
    assert {:ignored, _games} = Games.join_queue(games, playerb)
  end

  test "join_queue/2 player cannot join a game when they are in a requested game" do
    playera = Player.new(id: "a", name: "playera")
    playerb = Player.new(id: "b", name: "playerb")
    games = Games.new()

    {:requested, games} = Games.request(games, playera, playerb)
    {:game_started, games} = Games.request(games, playerb, playera)
    assert {:ignored, _games} = Games.join_queue(games, playera)
    assert {:ignored, _games} = Games.join_queue(games, playerb)
  end

  test "join_queue/2 end game and add player to queue if there is already a winner" do
    playera = Player.new(id: "a", name: "playera")
    playerb = Player.new(id: "b", name: "playerb")
    games = Games.new()

    {:enqueued, games} = Games.join_queue(games, playera)
    {:game_started, games} = Games.join_queue(games, playerb)
    game = Games.find_game_by_player(games, playera)
    games = Games.update(games, %Game{game | winner: playera})

    {:enqueued, games} = Games.join_queue(games, playera)
    refute Games.find_game_by_player(games, playerb)
    refute Games.find_game_by_player(games, playerb)

    {:game_started, games} = Games.join_queue(games, playerb)
    assert Games.find_game_by_player(games, playerb)
    assert Games.find_game_by_player(games, playerb)
  end

  test "outgoing_requests/2" do
    playera = Player.new(id: "a")
    playerb = Player.new(id: "b")
    playerc = Player.new(id: "c")

    games = Games.new()
    {:requested, games} = Games.request(games, playera, playerb)
    {:requested, games} = Games.request(games, playera, playerc)

    actual = Games.outgoing_requests(games, playera)
    expected = [playerb, playerc]

    assert Enum.sort(actual) == Enum.sort(expected)
  end

  test "leave_queue/2" do
    playera = Player.new(id: "a")

    games = Games.new()
    {:enqueued, games} = Games.join_queue(games, playera)
    games = Games.leave_queue(games, playera)
    refute Games.waiting?(games, playera)
  end

  test "outgoing_requests/2 ignore duplicates" do
    playera = Player.new(id: "a")
    playerb = Player.new(id: "b")

    games = Games.new()
    {:requested, games} = Games.request(games, playera, playerb)
    {:ignored, games} = Games.request(games, playera, playerb)
    assert Games.outgoing_requests(games, playera) == [playerb]
  end

  test "update/2" do
    playera = Player.new(id: "a", name: "playera")
    playerb = Player.new(id: "b", name: "playerb")

    games = Games.new()
    {:enqueued, games} = Games.join_queue(games, playera)
    {:game_started, games} = Games.join_queue(games, playerb)

    game = Games.find_game_by_player(games, playera)
    updated_game = Game.drop(game, Game.player1(game), 0)
    %Games{} = games = Games.update(games, updated_game)
    assert Games.find_game_by_player(games, playera) == updated_game
  end

  test "waiting?/2" do
    playera = Player.new(id: "a", name: "playera")
    playerb = Player.new(id: "b", name: "playerb")

    games = Games.new()
    refute Games.waiting?(games, playera)
    refute Games.waiting?(games, playerb)
    {:enqueued, games} = Games.join_queue(games, playera)
    assert Games.waiting?(games, playera)
    {:game_started, games} = Games.join_queue(games, playerb)
    refute Games.waiting?(games, playera)
    refute Games.waiting?(games, playerb)
  end

  test "quit/2" do
    playera = Player.new(id: "a", name: "playera")
    playerb = Player.new(id: "b", name: "playerb")

    games = Games.new()
    {:enqueued, games} = Games.join_queue(games, playera)
    {:game_started, games} = Games.join_queue(games, playerb)

    assert {:ok, games} = Games.quit(games, playera)
    assert games.queue == []

    assert Games.find_game_by_player(games, playera) == nil
    assert Games.find_game_by_player(games, playerb) == nil
  end

  test "request/3" do
    playera = Player.new(id: "a", name: "playera")
    playerb = Player.new(id: "b", name: "playerb")

    games = Games.new()
    {:requested, games} = Games.request(games, playera, playerb)
    {:game_started, games} = Games.request(games, playerb, playera)

    assert Games.find_game_by_player(games, playera)
    assert Games.find_game_by_player(games, playerb)

    # make sure we cleanup the request
    assert games.requests == []
  end

  test "request/3 requester already in a game" do
    playera = Player.new(id: "a", name: "playera")
    playerb = Player.new(id: "b", name: "playerb")

    games = Games.new()
    {:requested, games} = Games.request(games, playera, playerb)
    {:game_started, games} = Games.request(games, playerb, playera)
    {:ignored, games} = Games.request(games, playerb, playera)

    # make sure there is no request
    assert games.requests == []
  end
end
