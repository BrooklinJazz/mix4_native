defmodule Mix4Web.Mix4LiveTest do
  use Mix4Test.LiveViewNativeCase
  alias Mix4.Games.Player
  alias Mix4.GamesServer

  setup do
    GamesServer.wipe()
    :ok
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
    {:ok, _view, html} = live(conn, ~p"/")

    assert html =~ "Mix4"
  end

  @platforms [:swiftui, :web]
  cross_platform_test "connected mount _ game already exists", %{conn: conn} do
    playera = Player.new()
    playerb = Player.new()
    GamesServer.join_queue(playera)
    GamesServer.join_queue(playerb)
    assert {:error, {:live_redirect, %{to: path}}} = conn |> set_player(playera) |> live(~p"/")
    assert "/game/" <> _id = path
  end

  @platforms [:swiftui, :web]
  cross_platform_test "two players join game", %{conn: conn} do
    {:ok, viewa, _html} = conn |> set_player(Player.new()) |> live(~p"/")
    {:ok, viewb, _html} = conn |> set_player(Player.new()) |> live(~p"/")
    viewa |> element("#play-online") |> render_click()
    viewb |> element("#play-online") |> render_click()

    {path, _flash} = assert_redirect(viewa)
    assert "/game/" <> _id = path

    {path, _flash} = assert_redirect(viewb)
    assert "/game/" <> _id = path
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
  cross_platform_test "display player list", %{conn: conn} do
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

  @platforms [:swiftui, :web]
  cross_platform_test "request game triggers already requested styles", %{conn: conn} do
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

  @platforms [:swiftui, :web]
  cross_platform_test "request and accept a game between two players", %{conn: conn} do
    playera = Player.new()
    playerb = Player.new()
    {:ok, viewa, _html} = conn |> set_player(playera) |> live("/")
    {:ok, viewb, _html} = conn |> set_player(playerb) |> live("/")

    viewa |> element("#request-player-#{playerb.id}") |> render_click()
    viewb |> element("#request-player-#{playera.id}") |> render_click()

    {path, _flash} = assert_redirect(viewa)
    assert "/game/" <> _id = path

    {path, _flash} = assert_redirect(viewb)
    assert "/game/" <> _id = path
  end

  defp set_player(conn, player) do
    Plug.Test.init_test_session(conn, %{current_player: player})
  end
end
