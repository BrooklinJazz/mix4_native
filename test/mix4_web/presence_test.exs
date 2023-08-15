defmodule Mix4Web.PresenceTest do
  use ExUnit.Case, async: false
  doctest Mix4Web.Presence
  alias Mix4Web.Presence
  alias Mix4.Games.Game

  test "track_player/3 no existing game" do
    playera = Mix4.Games.Player.new(id: "a", name: "playera")
    playerb = Mix4.Games.Player.new(id: "b", name: "playerb")
    Presence.track_player(self(), playera, nil)
    Presence.track_player(self(), playerb, nil)

    assert [
             %{struct: ^playera, game_id: nil},
             %{struct: ^playerb, game_id: nil}
           ] = Presence.players()
  end

  test "track_player/3 existing game" do
    playera = Mix4.Games.Player.new(id: "a", name: "playera")
    playerb = Mix4.Games.Player.new(id: "b", name: "playerb")
    game = Game.new(playera, playerb)
    game_id = game.id
    Presence.track_player(self(), playera, game.id)
    Presence.track_player(self(), playerb, game.id)

    assert [
             %{struct: ^playera, game_id: ^game_id},
             %{struct: ^playerb, game_id: ^game_id}
           ] = Presence.players()
  end

  test "track_in_game/3" do
    playera = Mix4.Games.Player.new(id: "a", name: "playera")
    playerb = Mix4.Games.Player.new(id: "b", name: "playerb")
    Presence.track_player(self(), playera, nil)
    Presence.track_player(self(), playerb, nil)

    game = Game.new(playera, playerb)
    game_id = game.id

    Presence.track_in_game(self(), playera, game_id)
    Presence.track_in_game(self(), playerb, game_id)

    assert [
             %{struct: ^playera, game_id: ^game_id},
             %{struct: ^playerb, game_id: ^game_id}
           ] = Presence.players()
  end

  test "track_in_game/3 remove player from game" do
    playera = Mix4.Games.Player.new(id: "a", name: "playera")
    playerb = Mix4.Games.Player.new(id: "b", name: "playerb")
    Presence.track_player(self(), playera, nil)
    Presence.track_player(self(), playerb, nil)

    game = Game.new(playera, playerb)

    Presence.track_in_game(self(), playera, game.id)
    Presence.track_in_game(self(), playerb, game.id)

    Presence.track_in_game(self(), playera, nil)
    Presence.track_in_game(self(), playerb, nil)

    assert [
             %{struct: ^playera, game_id: nil},
             %{struct: ^playerb, game_id: nil}
           ] = Presence.players()
  end
end
