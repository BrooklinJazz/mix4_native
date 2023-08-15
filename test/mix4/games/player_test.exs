defmodule Mix4.Games.PlayerTest do
  use ExUnit.Case
  doctest Mix4.Games.Player
  alias Mix4.Games.Player

  test "new/1 without fields" do
    assert %Player{} = Player.new()
  end

  test "new/1 with fields" do
    assert %Player{id: "1", name: "player1"} = Player.new(id: "1", name: "player1")
  end
end
