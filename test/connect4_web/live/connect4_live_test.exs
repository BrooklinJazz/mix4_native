defmodule Connect4Web.Connect4LiveTest do
  use Connect4Web.ConnCase, async: true
  alias Connect4Web.Connect4Live
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

  describe "two player online game" do
    test "both players can start game", %{conn: conn} do
      playera = Player.new()
      playerb = Player.new()
      {:ok, games_server} = GamesServer.start_link(name: nil)
      conna = player_conn(conn, playera, games_server)
      connb = player_conn(conn, playerb, games_server)
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

    test "both players can drop discs", %{conn: conn} do
      playera = Player.new()
      playerb = Player.new()
      {:ok, games_server} = GamesServer.start_link(name: nil)
      conna = player_conn(conn, playera, games_server)
      connb = player_conn(conn, playerb, games_server)
      {:ok, viewa, _html} = live(conna, "/")
      {:ok, viewb, _html} = live(connb, "/")

      viewa |> element("#play-online") |> render_click()
      viewb |> element("#play-online") |> render_click()

      assert %Game{} = game = GamesServer.find_game_by_player(games_server, playera)

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

    test "display players turn", %{conn: conn} do
      playera = Player.new()
      playerb = Player.new()
      {:ok, games_server} = GamesServer.start_link(name: nil)
      conna = player_conn(conn, playera, games_server)
      connb = player_conn(conn, playerb, games_server)
      {:ok, viewa, _html} = live(conna, "/")
      {:ok, viewb, _html} = live(connb, "/")

      viewa |> element("#play-online") |> render_click()
      viewb |> element("#play-online") |> render_click()

      assert %Game{} = game = GamesServer.find_game_by_player(games_server, playera)

      {view1, view2} =
        case Game.player1(game) do
          ^playera -> {viewa, viewb}
          ^playerb -> {viewb, viewa}
        end

      assert has_element?(view1, "#your-turn")
      assert has_element?(view2, "#opponents-turn")

      view1 |> element("#column-0") |> render_click()

      assert has_element?(view1, "#opponents-turn")
      assert has_element?(view2, "#your-turn")
    end

    test "player wins", %{conn: conn} do
      playera = Player.new()
      playerb = Player.new()
      {:ok, games_server} = GamesServer.start_link(name: nil)
      conna = player_conn(conn, playera, games_server)
      connb = player_conn(conn, playerb, games_server)
      {:ok, viewa, _html} = live(conna, "/")
      {:ok, viewb, _html} = live(connb, "/")

      viewa |> element("#play-online") |> render_click()
      viewb |> element("#play-online") |> render_click()

      assert %Game{} = game = GamesServer.find_game_by_player(games_server, playera)

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

    test "player leaves and rejoins", %{conn: conn} do
      playera = Player.new()
      playerb = Player.new()
      {:ok, games_server} = GamesServer.start_link(name: nil)
      conna = player_conn(conn, playera, games_server)
      connb = player_conn(conn, playerb, games_server)
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
    test "hover styles", %{conn: conn} do
      playera = Player.new()
      playerb = Player.new()
      {:ok, games_server} = GamesServer.start_link(name: nil)
      conna = player_conn(conn, playera, games_server)
      connb = player_conn(conn, playerb, games_server)
      {:ok, viewa, _html} = live(conna, "/")
      {:ok, viewb, _html} = live(connb, "/")

      viewa |> element("#play-online") |> render_click()
      viewb |> element("#play-online") |> render_click()

      assert %Game{} = game = GamesServer.find_game_by_player(games_server, playera)

      {view1, view2} =
        case Game.player1(game) do
          ^playera -> {viewa, viewb}
          ^playerb -> {viewb, viewa}
        end

      assert view1 |> element("#cell-0-5") |> render() =~ "group-hover:bg-red-500"
      view1 |> element("#column-0") |> render_click()
      assert view2 |> element("#cell-1-5") |> render() =~ "group-hover:bg-yellow-500"
    end

    test "play again", %{conn: conn} do
      playera = Player.new()
      playerb = Player.new()
      {:ok, games_server} = GamesServer.start_link(name: nil)
      conna = player_conn(conn, playera, games_server)
      connb = player_conn(conn, playerb, games_server)
      {:ok, viewa, _html} = live(conna, "/")
      {:ok, viewb, _html} = live(connb, "/")

      viewa |> element("#play-online") |> render_click()
      viewb |> element("#play-online") |> render_click()

      assert %Game{} = game = GamesServer.find_game_by_player(games_server, playera)

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

      assert view1 |> element("#play-online") |> render_click()
      assert view2 |> element("#play-online") |> render_click()

      assert has_element?(view1, "#board")
      assert has_element?(view2, "#board")
    end

    test "quit", %{conn: conn} do
      playera = Player.new()
      playerb = Player.new()
      {:ok, games_server} = GamesServer.start_link(name: nil)
      conna = player_conn(conn, playera, games_server)
      connb = player_conn(conn, playerb, games_server)
      {:ok, viewa, _html} = live(conna, "/")
      {:ok, viewb, _html} = live(connb, "/")

      viewa |> element("#play-online") |> render_click()
      viewb |> element("#play-online") |> render_click()

      assert %Game{} = game = GamesServer.find_game_by_player(games_server, playera)

      {view1, view2} =
        case Game.player1(game) do
          ^playera -> {viewa, viewb}
          ^playerb -> {viewb, viewa}
        end

      assert has_element?(view1, "#board")
      assert has_element?(view2, "#board")
      view1 |> element("#quit-game") |> render_click()
      refute has_element?(view1, "#board")
      refute has_element?(view2, "#board")

      assert view2 |> render() =~ "Your opponent left the game."
      refute view1 |> render() =~ "Your opponent left the game."
    end

    test "turn timer", %{conn: conn} do
      playera = Player.new()
      playerb = Player.new()
      {:ok, games_server} = GamesServer.start_link(name: nil)
      conna = player_conn(conn, playera, games_server)
      connb = player_conn(conn, playerb, games_server)
      {:ok, viewa, _html} = live(conna, "/")
      {:ok, viewb, _html} = live(connb, "/")

      viewa |> element("#play-online") |> render_click()
      viewb |> element("#play-online") |> render_click()

      assert %Game{} = game = GamesServer.find_game_by_player(games_server, playera)

      {view1, view2} =
        case Game.player1(game) do
          ^playera -> {viewa, viewb}
          ^playerb -> {viewb, viewa}
        end

      assert view1 |> element("#turn-timer") |> render() =~ "30"
      assert view2 |> element("#turn-timer") |> render() =~ "30"

      # Wait for the turn timer to tick down
      Process.sleep(1000)
      assert view1 |> element("#turn-timer") |> render() =~ "29"
      assert view2 |> element("#turn-timer") |> render() =~ "29"
    end

    test "turn timer runs out", %{conn: conn} do
      playera = Player.new()
      playerb = Player.new()
      {:ok, games_server} = GamesServer.start_link(name: nil)
      conna = player_conn(conn, playera, games_server)
      connb = player_conn(conn, playerb, games_server)
      {:ok, viewa, _html} = live(conna, "/")
      {:ok, viewb, _html} = live(connb, "/")

      viewa |> element("#play-online") |> render_click()
      viewb |> element("#play-online") |> render_click()

      assert %Game{} = game = GamesServer.find_game_by_player(games_server, playera)

      {view1, view2} =
        case Game.player1(game) do
          ^playera -> {viewa, viewb}
          ^playerb -> {viewb, viewa}
        end

      GamesServer.update(games_server, %Game{
        game
        | turn_end_time: DateTime.add(DateTime.utc_now(:second), -100, :second)
      })

      # trigger remaining_time to be recalculated
      send(view1.pid, :tick)
      send(view2.pid, :tick)

      refute view1 |> element("#turn-timer") |> render() =~ "30"
      refute view1 |> element("#turn-timer") |> render() =~ "-100"
      refute view2 |> element("#turn-timer") |> render() =~ "30"
      refute view2 |> element("#turn-timer") |> render() =~ "-100"

      assert view1 |> element("#turn-timer") |> render() =~ "0"
      assert view2 |> element("#turn-timer") |> render() =~ "0"

      # swap turns automatically
      assert has_element?(view1, "#opponents-turn")
      assert has_element?(view2, "#your-turn")
    end
  end

  describe "players online" do
    test "display player list", %{conn: conn} do
      playera = Player.new(name: "playera")
      playerb = Player.new(name: "playerb")
      playerc = Player.new(name: "playerc")
      {:ok, games_server} = GamesServer.start_link(name: nil)
      conna = player_conn(conn, playera, games_server)
      connb = player_conn(conn, playerb, games_server)
      connc = player_conn(conn, playerc, games_server)
      {:ok, viewa, _html} = live(conna, "/")
      {:ok, viewb, _html} = live(connb, "/")
      {:ok, viewc, _html} = live(connc, "/")

      refute viewa |> element("#players-list") |> render() =~ playera.name
      assert viewa |> element("#players-list") |> render() =~ playerb.name
      assert viewa |> element("#players-list") |> render() =~ playerc.name

      refute viewb |> element("#players-list") |> render() =~ playerb.name
      assert viewb |> element("#players-list") |> render() =~ playera.name
      assert viewb |> element("#players-list") |> render() =~ playerc.name

      refute viewc |> element("#players-list") |> render() =~ playerc.name
      assert viewc |> element("#players-list") |> render() =~ playera.name
      assert viewc |> element("#players-list") |> render() =~ playerb.name
    end

    test "request game triggers already requested styles", %{conn: conn} do
      playera = Player.new(name: "playera")
      playerb = Player.new(name: "playerb")
      {:ok, games_server} = GamesServer.start_link(name: nil)
      conna = player_conn(conn, playera, games_server)
      connb = player_conn(conn, playerb, games_server)
      {:ok, viewa, _html} = live(conna, "/")
      {:ok, viewb, _html} = live(connb, "/")

      assert viewa |> element("#request-player-#{playerb.id}") |> render() =~ "Request"
      viewa |> element("#request-player-#{playerb.id}") |> render_click()
      assert viewa |> element("#request-player-#{playerb.id}") |> render() =~ "Requested"

      assert viewb |> element("#request-player-#{playera.id}") |> render() =~
               "Accept Request"
    end

    test "request and accept a game between two players", %{conn: conn} do
      playera = Player.new(name: "playera")
      playerb = Player.new(name: "playerb")
      {:ok, games_server} = GamesServer.start_link(name: nil)
      conna = player_conn(conn, playera, games_server)
      connb = player_conn(conn, playerb, games_server)
      {:ok, viewa, _html} = live(conna, "/")
      {:ok, viewb, _html} = live(connb, "/")

      viewa |> element("#request-player-#{playerb.id}") |> render_click()
      viewb |> element("#request-player-#{playera.id}") |> render_click()

      assert has_element?(viewa, "#board")
      assert has_element?(viewb, "#board")

      assert GamesServer.find_game_by_player(games_server, playera)
      assert GamesServer.find_game_by_player(games_server, playerb)

      assert GamesServer.find_game_by_player(games_server, playera) ==
               GamesServer.find_game_by_player(games_server, playerb)
    end

    test "cannot request a game with a player already in a game", %{conn: conn} do
      playera = Player.new(name: "playera")
      playerb = Player.new(name: "playerb")
      playerc = Player.new(name: "playerc")
      {:ok, games_server} = GamesServer.start_link(name: nil)
      conna = player_conn(conn, playera, games_server)
      connb = player_conn(conn, playerb, games_server)
      connc = player_conn(conn, playerc, games_server)
      {:ok, viewa, _html} = live(conna, "/")
      {:ok, viewb, _html} = live(connb, "/")
      {:ok, viewc, _html} = live(connc, "/")

      viewa |> element("#request-player-#{playerb.id}") |> render_click()
      viewb |> element("#request-player-#{playera.id}") |> render_click()

      refute viewc |> has_element?("#request-player-#{playera.id}")
      refute viewc |> has_element?("#request-player-#{playerb.id}")
      assert viewc |> has_element?("#currently-playing-#{playera.id}")
      assert viewc |> has_element?("#currently-playing-#{playerb.id}")
    end

    test "quitting clears the currently playing styles", %{conn: conn} do
      playera = Player.new(name: "playera")
      playerb = Player.new(name: "playerb")
      {:ok, games_server} = GamesServer.start_link(name: nil)
      conna = player_conn(conn, playera, games_server)
      connb = player_conn(conn, playerb, games_server)
      {:ok, viewa, _html} = live(conna, "/")
      {:ok, viewb, _html} = live(connb, "/")

      viewa |> element("#request-player-#{playerb.id}") |> render_click()
      viewb |> element("#request-player-#{playera.id}") |> render_click()
      viewb |> element("#quit-game") |> render_click()

      refute viewa |> has_element?("#currently-playing-#{playerb.id}")
      refute viewb |> has_element?("#currently-playing-#{playera.id}")

      refute viewa |> element("#request-player-#{playerb.id}") |> render() =~ "Requested"
      refute viewb |> element("#request-player-#{playera.id}") |> render() =~ "Accept Request"
    end
  end

  test "sort_players" do
    [
      no_request_player1,
      no_request_player2,
      outgoing_request_player1,
      outgoing_request_player2,
      incoming_request_player1,
      incoming_request_player2
    ] = players = Enum.map(1..6, fn _ -> Player.new() end)

    assert [player1, player2, player3, player4, player5, player6] =
             Connect4Live.sort_players(
               Enum.shuffle(players),
               [incoming_request_player1, incoming_request_player2],
               [outgoing_request_player1, outgoing_request_player2]
             )

    assert incoming_request_player1 in [player1, player2]
    assert incoming_request_player2 in [player1, player2]
    assert outgoing_request_player1 in [player3, player4]
    assert outgoing_request_player1 in [player3, player4]
    assert no_request_player1 in [player5, player6]
    assert no_request_player2 in [player5, player6]
  end

  defp player_conn(conn, player, game_server) do
    Plug.Test.init_test_session(conn,
      current_player: player,
      platform_id: @platform_id,
      game_server_pid: game_server
    )
  end
end
