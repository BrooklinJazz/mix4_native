defmodule Mix4Web.GameLiveTest do
  use Mix4Test.LiveViewNativeCase
  alias Mix4.GamesServer
  alias Mix4.Games.Game
  alias Mix4.Games.Player

  setup do
    GamesServer.wipe()
    playera = Player.new(name: "Player a")
    playerb = Player.new(name: "Player b")
    GamesServer.join_queue(playera)
    GamesServer.join_queue(playerb)
    game = GamesServer.find_game_by_player(playera)
    player1 = Game.player1(game)
    player2 = Game.player2(game)
    [player1: player1, player2: player2, game: game]
  end

  @platforms [:swiftui, :web]
  cross_platform_test "connected mount _ game exists", ctx do
    {:ok, view, _html} = ctx.conn |> set_player(ctx.player1) |> live(~p"/game/#{ctx.game}")
    assert has_element?(view, "#board")
  end

  @platforms [:swiftui, :web]
  cross_platform_test "connected mount _ player is not part of game", ctx do
    assert {:error, {:live_redirect, %{to: "/"}}} =
             ctx.conn |> set_player(Player.new()) |> live(~p"/game/non_existing_game_id")
  end

  @platforms [:swiftui, :web]
  cross_platform_test "connected mount _ game does not exist", ctx do
    assert {:error, {:live_redirect, %{to: "/"}}} = live(ctx.conn, ~p"/game/non_existing_game_id")
  end

  @platforms [:swiftui, :web]
  cross_platform_test "player drops disc", ctx do
    {:ok, view1, _html} = ctx.conn |> set_player(ctx.player1) |> live(~p"/game/#{ctx.game}")
    {:ok, view2, _html} = ctx.conn |> set_player(ctx.player2) |> live(~p"/game/#{ctx.game}")

    view1 |> element("#column-0") |> render_click()
    assert view1 |> element("#cell-0-5") |> render() =~ "player1"
    assert view2 |> element("#cell-0-5") |> render() =~ "player1"

    view2 |> element("#column-1") |> render_click()
    assert view1 |> element("#cell-1-5") |> render() =~ "player2"
    assert view2 |> element("#cell-1-5") |> render() =~ "player2"
  end

  @platforms [:swiftui, :web]
  cross_platform_test "display current turn", ctx do
    {:ok, view1, _html} = ctx.conn |> set_player(ctx.player1) |> live(~p"/game/#{ctx.game}")
    {:ok, view2, _html} = ctx.conn |> set_player(ctx.player2) |> live(~p"/game/#{ctx.game}")

    assert has_element?(view1, "#your-turn")
    assert has_element?(view2, "#waiting-for-opponent")

    view1 |> element("#column-0") |> render_click()
    assert has_element?(view1, "#waiting-for-opponent")
    assert has_element?(view2, "#your-turn")
  end

  @platforms [:swiftui, :web]
  cross_platform_test "player wins", ctx do
    {:ok, view1, _html} = ctx.conn |> set_player(ctx.player1) |> live(~p"/game/#{ctx.game}/")
    {:ok, view2, _html} = ctx.conn |> set_player(ctx.player2) |> live(~p"/game/#{ctx.game}/")

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
  cross_platform_test "quit", ctx do
    {:ok, view1, _html} = ctx.conn |> set_player(ctx.player1) |> live(~p"/game/#{ctx.game}/")
    {:ok, view2, _html} = ctx.conn |> set_player(ctx.player2) |> live(~p"/game/#{ctx.game}/")

    view1 |> element("#quit") |> render_click()

    {path, _flash} = assert_redirect(view1)
    assert path == ~p"/"

    assert view2 |> render() =~ "Your opponent left the game."
    refute GamesServer.find_game_by_id(ctx.game.id)

    view2 |> element("#quit") |> render_click()
    {path, _flash} = assert_redirect(view2)
    assert path == ~p"/"
  end

  defp set_player(conn, player) do
    Plug.Test.init_test_session(conn, %{current_player: player})
  end
end
