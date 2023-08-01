defmodule Connect4Web.Connect4LiveTest do
  use LiveViewNative.Test
  alias Connect4Web.Connect4Live
  alias Connect4.GamesServer
  alias Connect4.Games.Game
  alias Connect4.Games.Player

  # setup independent games server for every test to avoid named process issues.
  setup %{test: test_name, conn: conn} do
    {:ok, games_server} = GamesServer.start_link(name: test_name)

    {:ok,
     conn: Plug.Test.init_test_session(conn, %{games_server: games_server}),
     games_server: games_server}
  end

  @platform :web
  test "web platform id set correctly", %{conn: conn} do
    assert conn.private.live_view_connect_params == %{"_platform" => "web"}
  end

  @platform :swiftui
  test "swiftui platform id set correctly", %{conn: conn} do
    assert conn.private.live_view_connect_params == %{"_platform" => "swiftui"}
  end

  @platforms [:swiftui, :web]
  cross_platform_test "connected mount", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/")

    assert html =~ "Connect4"
  end

  @platforms [:swiftui, :web]
  cross_platform_test "two players join game", %{conn: conn} do
    {:ok, viewa, _html} = live(conn, "/")
    {:ok, viewb, _html} = live(conn, "/")
    viewa |> element("#play-online") |> render_click()
    assert viewa |> render() =~ "Waiting for opponent"
    viewb |> element("#play-online") |> render_click()

    assert has_element?(viewa, "#board")
    assert has_element?(viewb, "#board")
  end

  @platforms [:swiftui, :web]
  cross_platform_test "player drops disc", %{conn: conn, games_server: games_server} do
    playera = Player.new()
    playerb = Player.new()
    GamesServer.join_queue(games_server, playera)
    GamesServer.join_queue(games_server, playerb)
    player1 = GamesServer.find_game_by_player(games_server, playera) |> Game.player1()
    player2 = GamesServer.find_game_by_player(games_server, playera) |> Game.player2()

    {:ok, view1, _html} = conn |> set_player(player1) |> live("/")
    {:ok, view2, _html} = conn |> set_player(player2) |> live("/")

    assert has_element?(view1, "#board")
    assert has_element?(view2, "#board")

    view1 |> element("#column-0") |> render_click()
    assert view1 |> element("#cell-0-5") |> render() =~ "red"
    assert view2 |> element("#cell-0-5") |> render() =~ "red"

    view2 |> element("#column-1") |> render_click()
    assert view1 |> element("#cell-1-5") |> render() =~ "yellow"
    assert view2 |> element("#cell-1-5") |> render() =~ "yellow"
  end

  @platforms [:swiftui, :web]
  cross_platform_test "display current turn", %{conn: conn, games_server: games_server} do
    playera = Player.new()
    playerb = Player.new()
    GamesServer.join_queue(games_server, playera)
    GamesServer.join_queue(games_server, playerb)
    player1 = GamesServer.find_game_by_player(games_server, playera) |> Game.player1()
    player2 = GamesServer.find_game_by_player(games_server, playera) |> Game.player2()

    {:ok, view1, _html} = conn |> set_player(player1) |> live("/")
    {:ok, view2, _html} = conn |> set_player(player2) |> live("/")

    assert has_element?(view1, "#your-turn")
    assert has_element?(view2, "#opponents-turn")

    view1 |> element("#column-0") |> render_click()

    assert has_element?(view1, "#opponents-turn")
    assert has_element?(view2, "#your-turn")
  end

  @platforms [:swiftui, :web]
  cross_platform_test "player wins", %{conn: conn, games_server: games_server} do
    playera = Player.new()
    playerb = Player.new()
    GamesServer.join_queue(games_server, playera)
    GamesServer.join_queue(games_server, playerb)
    player1 = GamesServer.find_game_by_player(games_server, playera) |> Game.player1()
    player2 = GamesServer.find_game_by_player(games_server, playera) |> Game.player2()

    {:ok, view1, _html} = conn |> set_player(player1) |> live("/")
    {:ok, view2, _html} = conn |> set_player(player2) |> live("/")

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

  @platforms [:swiftui, :web]
  cross_platform_test "cancel queueing", %{conn: conn} do
    playera = Player.new()
    {:ok, view, _html} = conn |> set_player(playera) |> live("/")

    assert view |> element("#play-online") |> render_click() =~ "Waiting for opponent"
    refute view |> element("#leave-queue") |> render_click() =~ "Waiting for opponent"
    assert has_element?(view, "#play-online")
  end

  @platforms [:swiftui, :web]
  cross_platform_test "player leaves and rejoins remain in game", %{conn: conn} do
    playera = Player.new()
    playerb = Player.new()
    {:ok, view1, _html} = conn |> set_player(playera) |> live("/")
    {:ok, view2, _html} = conn |> set_player(playerb) |> live("/")

    view1 |> element("#play-online") |> render_click()
    view2 |> element("#play-online") |> render_click()

    {:ok, view1, _html} = conn |> set_player(playera) |> live("/")
    assert has_element?(view1, "#board")

    {:ok, view2, _html} = conn |> set_player(playerb) |> live("/")
    assert has_element?(view2, "#board")
  end

  @platform :web
  test "hover styles", %{conn: conn, games_server: games_server} do
    playera = Player.new()
    playerb = Player.new()
    GamesServer.join_queue(games_server, playera)
    GamesServer.join_queue(games_server, playerb)
    player1 = GamesServer.find_game_by_player(games_server, playera) |> Game.player1()
    player2 = GamesServer.find_game_by_player(games_server, playera) |> Game.player2()
    {:ok, view1, _html} = conn |> set_player(player1) |> live("/")
    {:ok, view2, _html} = conn |> set_player(player2) |> live("/")

    assert view1 |> element("#cell-0-5") |> render() =~ "group-hover"
    view1 |> element("#column-0") |> render_click()
    assert view2 |> element("#cell-1-5") |> render() =~ "group-hover"
  end

  @platforms [:swiftui, :web]
  cross_platform_test "play again", %{conn: conn, games_server: games_server} do
    playera = Player.new()
    playerb = Player.new()
    GamesServer.join_queue(games_server, playera)
    GamesServer.join_queue(games_server, playerb)
    player1 = GamesServer.find_game_by_player(games_server, playera) |> Game.player1()
    player2 = GamesServer.find_game_by_player(games_server, playera) |> Game.player2()
    {:ok, view1, _html} = conn |> set_player(player1) |> live("/")
    {:ok, view2, _html} = conn |> set_player(player2) |> live("/")

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

  @platforms [:swiftui, :web]
  cross_platform_test "quit", %{conn: conn, games_server: games_server} do
    playera = Player.new()
    playerb = Player.new()
    GamesServer.join_queue(games_server, playera)
    GamesServer.join_queue(games_server, playerb)
    player1 = GamesServer.find_game_by_player(games_server, playera) |> Game.player1()
    player2 = GamesServer.find_game_by_player(games_server, playera) |> Game.player2()
    {:ok, view1, _html} = conn |> set_player(player1) |> live("/")
    {:ok, view2, _html} = conn |> set_player(player2) |> live("/")

    view1 |> element("#quit-game") |> render_click()
    refute has_element?(view1, "#board")
    refute has_element?(view2, "#board")

    # I'm not sure how swiftui handles flash messages. TODO test this manually.
    assert view2 |> render() =~ "Your opponent left the game."
    refute view1 |> render() =~ "Your opponent left the game."
  end

  @platforms [:swiftui, :web]
  cross_platform_test "turn timer counts down", %{conn: conn} do
    playera = Player.new()
    playerb = Player.new()
    {:ok, viewa, _html} = conn |> set_player(playera) |> live("/")
    {:ok, viewb, _html} = conn |> set_player(playerb) |> live("/")

    assert viewa |> element("#play-online") |> render_click()
    assert viewb |> element("#play-online") |> render_click()

    assert viewa |> element("#turn-timer") |> render() =~ "30"
    assert viewb |> element("#turn-timer") |> render() =~ "30"

    # Wait for the turn timer to tick down
    Process.sleep(1000)
    assert viewa |> element("#turn-timer") |> render() =~ "29"
    assert viewb |> element("#turn-timer") |> render() =~ "29"
  end

  @platforms [:swiftui, :web]
  cross_platform_test "turn timer runs out", %{conn: conn, games_server: games_server} do
    playera = Player.new()
    playerb = Player.new()
    GamesServer.join_queue(games_server, playera)
    GamesServer.join_queue(games_server, playerb)
    game = GamesServer.find_game_by_player(games_server, playera)
    player1 = Game.player1(game)
    player2 = Game.player2(game)
    {:ok, view1, _html} = conn |> set_player(player1) |> live("/")
    {:ok, view2, _html} = conn |> set_player(player2) |> live("/")

    past_datetime = DateTime.add(DateTime.utc_now(:second), -100, :second)
    GamesServer.update(games_server, %Game{game | turn_end_time: past_datetime})

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

  @platform :web
  test "display player list", %{conn: conn} do
    playera = Player.new(name: "player a name")
    playerb = Player.new(name: "player b name")
    playerc = Player.new(name: "player c name")
    {:ok, viewa, _html} = conn |> set_player(playera) |> live("/")
    {:ok, viewb, _html} = conn |> set_player(playerb) |> live("/")
    {:ok, viewc, _html} = conn |> set_player(playerc) |> live("/")

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

  @platform :web
  test "request game triggers already requested styles", %{conn: conn} do
    playera = Player.new()
    playerb = Player.new()
    {:ok, viewa, _html} = conn |> set_player(playera) |> live("/")
    {:ok, viewb, _html} = conn |> set_player(playerb) |> live("/")

    assert viewa |> element("#request-player-#{playerb.id}") |> render() =~ "Request"
    viewa |> element("#request-player-#{playerb.id}") |> render_click()
    assert viewa |> element("#request-player-#{playerb.id}") |> render() =~ "Requested"

    assert viewb |> element("#request-player-#{playera.id}") |> render() =~
             "Accept Request"
  end

  @platform :web
  test "request and accept a game between two players", %{conn: conn} do
    playera = Player.new()
    playerb = Player.new()
    {:ok, viewa, _html} = conn |> set_player(playera) |> live("/")
    {:ok, viewb, _html} = conn |> set_player(playerb) |> live("/")

    viewa |> element("#request-player-#{playerb.id}") |> render_click()
    viewb |> element("#request-player-#{playera.id}") |> render_click()

    assert has_element?(viewa, "#board")
    assert has_element?(viewb, "#board")
  end

  @platform :web
  test "cannot request a game with a player already in a game", %{conn: conn} do
    playera = Player.new(name: "playera")
    playerb = Player.new(name: "playerb")
    playerc = Player.new(name: "playerc")
    {:ok, viewa, _html} = conn |> set_player(playera) |> live("/")
    {:ok, viewb, _html} = conn |> set_player(playerb) |> live("/")
    {:ok, viewc, _html} = conn |> set_player(playerc) |> live("/")

    viewa |> element("#request-player-#{playerb.id}") |> render_click()
    viewb |> element("#request-player-#{playera.id}") |> render_click()

    refute viewc |> has_element?("#request-player-#{playera.id}")
    refute viewc |> has_element?("#request-player-#{playerb.id}")
    assert viewc |> has_element?("#currently-playing-#{playera.id}")
    assert viewc |> has_element?("#currently-playing-#{playerb.id}")
  end

  @platform :web
  test "quitting clears the currently playing styles", %{conn: conn} do
    playera = Player.new(name: "playera")
    playerb = Player.new(name: "playerb")
    {:ok, viewa, _html} = conn |> set_player(playera) |> live("/")
    {:ok, viewb, _html} = conn |> set_player(playerb) |> live("/")

    viewa |> element("#request-player-#{playerb.id}") |> render_click()
    viewb |> element("#request-player-#{playera.id}") |> render_click()
    viewb |> element("#quit-game") |> render_click()

    refute viewa |> has_element?("#currently-playing-#{playerb.id}")
    refute viewb |> has_element?("#currently-playing-#{playera.id}")

    refute viewa |> element("#request-player-#{playerb.id}") |> render() =~ "Requested"
    refute viewb |> element("#request-player-#{playera.id}") |> render() =~ "Accept Request"
  end

  test "sort_players/3" do
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

  defp set_player(conn, player) do
    Plug.Test.init_test_session(conn, %{current_player: player})
  end
end
