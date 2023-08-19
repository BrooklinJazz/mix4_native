defmodule Mix4Web.GameLiveTest do
  use Mix4Web.ConnCase, async: false
  alias Mix4Web.GameLive
  alias Mix4.GamesServer
  alias Mix4.Games.Game
  alias Mix4.Games.Player

  setup do
    GamesServer.wipe()
    :ok
  end

  describe "web" do
    test "connected mount _ game exists", %{conn: conn, test: test_name} do
      playera = Player.new()
      playerb = Player.new()
      GamesServer.join_queue(playera)
      GamesServer.join_queue(playerb)
      game = GamesServer.find_game_by_player(playera)

      assert {:ok, _view, html} = live(conn, ~p"/game/#{game}")
    end

    test "connected mount _ game does not exist", %{conn: conn, test: test_name} do
      {:ok, games_server} = GamesServer.start_link(name: test_name)

      assert {:error, {:redirect, %{to: "/"}}} = live(conn, ~p"/game/non_existing_game_id")
    end
  end
end
