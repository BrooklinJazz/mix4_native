defmodule Connect4Web.Connect4LiveTest do
  use Connect4Web.ConnCase, async: true
  alias Connect4.GamesServer
  alias Connect4.Games.Game
  alias Connect4.Games.Player
  # run the following command to test on swift
  # PLATFORM_ID=swiftui mix test --exclude=web
  @platform_id String.to_atom(System.get_env("PLATFORM_ID") || "web")

  test "web _ connected mount", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/")

    assert html =~ "Connect4"
  end

  describe "web _ two player online game" do
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
      assert view1 |> render() =~ "Waiting for opponent"
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

    test "display players turn", %{
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

      assert has_element?(view1, "#your-turn")
      assert has_element?(view2, "#opponent-turn")

      view1 |> element("#column-0") |> render_click()

      assert has_element?(view1, "#opponent-turn")
      assert has_element?(view2, "#your-turn")
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

    @tag :web
    test "hover styles", %{
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

      assert view1 |> element("#cell-0-5") |> render() =~ "group-hover:bg-red-500"
      view1 |> element("#column-0") |> render_click()
      assert view2 |> element("#cell-1-5") |> render() =~ "group-hover:bg-yellow-500"
    end
  end
end
