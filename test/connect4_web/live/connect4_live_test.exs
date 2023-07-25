defmodule Connect4Web.Connect4LiveTest do
  use Connect4Web.ConnCase, async: true
  alias Connect4.GamesServer
  alias Connect4.Games.Game
  alias Connect4.Games.Player
  # run tests with $PLATFORM_ID=swiftui to test on swift.
  @platform_id String.to_atom(System.get_env("PLATFORM_ID") || "web")

  test "web _ connected mount", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/")

    assert html =~ "Connect4"
  end

  # describe "web _ local game" do
  #   test "start local game", %{conn: conn} do
  #     {:ok, view, _html} = live(conn, "/")

  #     refute element(view, "#board")
  #     assert view |> element("#player-vs-player") |> render_click()
  #     assert element(view, "#board")
  #   end

  #   test "local players can drop discs", %{conn: conn} do
  #     {:ok, view, _html} = live(conn, "/")

  #     assert view |> element("#player-vs-player") |> render_click()
  #     assert view |> element("#cell-0-5") |> render() =~ "black"
  #     assert view |> element("#cell-1-5") |> render() =~ "black"

  #     view |> element("#column-0") |> render_click()
  #     assert view |> element("#cell-0-5") |> render() =~ "red"

  #     view |> element("#column-1") |> render_click()
  #     assert view |> element("#cell-1-5") |> render() =~ "yellow"
  #   end

  #   test "player 1 can win", %{conn: conn} do
  #     conn = Plug.Test.init_test_session(conn, current_player: Player.new(id: "1", name: "name1"))
  #     {:ok, view, _html} = live(conn, "/")

  #     assert view |> element("#player-vs-player") |> render_click()
  #     view |> element("#column-0") |> render_click()
  #     view |> element("#column-1") |> render_click()
  #     view |> element("#column-0") |> render_click()
  #     view |> element("#column-1") |> render_click()
  #     view |> element("#column-0") |> render_click()
  #     view |> element("#column-1") |> render_click()
  #     view |> element("#column-0") |> render_click()

  #     assert view |> render() =~ "name1 wins!"
  #   end

  #   test "player 2 can win", %{conn: conn} do
  #     {:ok, view, _html} = live(conn, "/")

  #     view |> element("#column-0") |> render_click()
  #     view |> element("#column-2") |> render_click()
  #     view |> element("#column-1") |> render_click()
  #     view |> element("#column-2") |> render_click()
  #     view |> element("#column-0") |> render_click()
  #     view |> element("#column-2") |> render_click()
  #     view |> element("#column-1") |> render_click()
  #     view |> element("#column-2") |> render_click()

  #     assert view |> render() =~ "yellow wins!"
  #   end
  # end

  describe "web _ online game" do
    setup %{conn: conn} do
      playera = Player.new(id: "a", name: "namea")
      playerb = Player.new(id: "b", name: "nameb")
      # sets up unique GamesServer per test
      {:ok, pid} = GamesServer.start_link(name: nil)

      conna =
        Plug.Test.init_test_session(conn,
          current_player: playera,
          platform_id: @platform_id,
          game_server_pid: pid
        )

      connb =
        Plug.Test.init_test_session(conn,
          current_player: playerb,
          platform_id: @platform_id,
          game_server_pid: pid
        )

      [playera: playera, playerb: playerb, conna: conna, connb: connb, games_server: pid]
    end

    test "both players can start game", %{conna: conna, connb: connb} do
      {:ok, view1, _html} = live(conna, "/")
      {:ok, view2, _html} = live(connb, "/")

      refute has_element?(view1, "#board")
      refute has_element?(view2, "#board")

      view1 |> element("#play-online") |> render_click()
      # assert view1 |> render() =~ "Waiting for opponent"
      view2 |> element("#play-online") |> render_click()

      assert has_element?(view1, "#board")
      assert has_element?(view2, "#board")
    end

    test "both players can drop discs", %{
      conna: conna,
      connb: connb,
      playera: playera,
      playerb: playerb,
      games_server: games_server
    } do
      {:ok, viewa, _html} = live(conna, "/")
      {:ok, viewb, _html} = live(connb, "/")

      viewa |> element("#play-online") |> render_click()
      viewb |> element("#play-online") |> render_click()

      assert %Game{} = game = GamesServer.find_game(games_server, playera)

      {view1, view2} =
        case Game.player1(game) do
          ^playera -> {viewa, viewb}
          ^playerb -> {viewb, viewa}
        end

      view1 |> element("#column-0") |> render_click()
      view2 |> element("#column-1") |> render_click()
      assert view1 |> element("#cell-0-5") |> render() =~ "red"
      assert view2 |> element("#cell-0-5") |> render() =~ "red"

      assert view1 |> element("#cell-1-5") |> render() =~ "yellow"
      assert view2 |> element("#cell-1-5") |> render() =~ "yellow"
    end

    test "player wins", %{
      conna: conna,
      connb: connb,
      playera: playera,
      playerb: playerb,
      games_server: games_server
    } do
      {:ok, viewa, _html} = live(conna, "/")
      {:ok, viewb, _html} = live(connb, "/")

      viewa |> element("#play-online") |> render_click()
      viewb |> element("#play-online") |> render_click()

      assert %Game{} = game = GamesServer.find_game(games_server, playera)

      {view1, view2} =
        case Game.player1(game) do
          ^playera -> {viewa, viewb}
          ^playerb -> {viewb, viewa}
        end

      view1 |> element("#column-0") |> render_click()
      view2 |> element("#column-1") |> render_click()
      view1 |> element("#column-0") |> render_click()
      view2 |> element("#column-1") |> render_click()
      view1 |> element("#column-0") |> render_click()
      view2 |> element("#column-1") |> render_click()
      view1 |> element("#column-0") |> render_click()

      assert view1 |> render() =~ "You win"
      assert view2 |> render() =~ "You lose"
    end

    test "player leaves and rejoins", %{conna: conna, connb: connb} do
      {:ok, view1, _html} = live(conna, "/")
      {:ok, view2, _html} = live(connb, "/")

      view1 |> element("#play-online") |> render_click()
      view2 |> element("#play-online") |> render_click()

      {:ok, view1, _html} = live(conna, "/")
      assert has_element?(view1, "#board")

      {:ok, view2, _html} = live(connb, "/")
      assert has_element?(view2, "#board")
    end
  end
end
