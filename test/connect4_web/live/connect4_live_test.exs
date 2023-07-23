defmodule Connect4Web.Connect4LiveTest do
  use Connect4Web.ConnCase, async: true
  alias Connect4.Player
  # run tests with $PLATFORM_ID=swiftui to test on swift.
  @platform_id if System.get_env("PLATFORM_ID"),
                 do: String.to_atom(System.get_env("PLATFORM_ID")) || :web

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
  #     conn = Plug.Test.init_test_session(conn, current_player: Player.new("1", "name1"))
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
    test "both players can start game", %{conn: conn} do
      conn1 =
        Plug.Test.init_test_session(conn,
          current_player: Player.new("1", "name1"),
          platform_id: @platform_id
        )

      conn2 =
        Plug.Test.init_test_session(conn,
          current_player: Player.new("2", "name2"),
          platform_id: @platform_id
        )

      {:ok, view1, _html} = live(conn1, "/")
      {:ok, view2, _html} = live(conn2, "/")

      refute has_element?(view1, "#board")
      refute has_element?(view2, "#board")

      view1 |> element("#play-online") |> render_click()
      assert view1 |> render() =~ "Waiting for opponent"
      view2 |> element("#play-online") |> render_click()

      assert has_element?(view1, "#board")
      assert has_element?(view2, "#board")

      assert view1 |> element("#opponent") |> render() =~ "name2"
      assert view2 |> element("#opponent") |> render() =~ "name1"
    end

    test "both players can drop discs", %{conn: conn} do
      conn1 =
        Plug.Test.init_test_session(conn,
          current_player: Player.new("1", "name1"),
          platform_id: @platform_id
        )

      conn2 =
        Plug.Test.init_test_session(conn,
          current_player: Player.new("2", "name2"),
          platform_id: @platform_id
        )

      {:ok, view1, _html} = live(conn1, "/")
      {:ok, view2, _html} = live(conn2, "/")

      view1 |> element("#play-online") |> render_click()
      view2 |> element("#play-online") |> render_click()

      view1 |> element("#column-0") |> render_click()
      assert view1 |> element("#cell-0-5") |> render() =~ "red"
      assert view2 |> element("#cell-0-5") |> render() =~ "red"

      view2 |> element("#column-1") |> render_click()
      assert view1 |> element("#cell-1-5") |> render() =~ "yellow"
      assert view2 |> element("#cell-1-5") |> render() =~ "yellow"
    end

    test "player wins", %{conn: conn} do
      conn1 =
        Plug.Test.init_test_session(conn,
          current_player: Player.new("1", "name1"),
          platform_id: @platform_id
        )

      conn2 =
        Plug.Test.init_test_session(conn,
          current_player: Player.new("2", "name2"),
          platform_id: @platform_id
        )

      {:ok, view1, _html} = live(conn1, "/")
      {:ok, view2, _html} = live(conn2, "/")

      view1 |> element("#play-online") |> render_click()
      view2 |> element("#play-online") |> render_click()

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
  end

  # describe "swiftui" do
  #   test "render the board", %{conn: conn} do
  #     conn =
  #       Plug.Test.init_test_session(conn,
  #         current_player: Player.new("1", "name1"),
  #         platform_id: :swiftui
  #       )

  #     {:ok, view, _html} = live(conn, "/")
  #     assert view |> has_element?("#board")
  #   end

  #   test "players can drop disc", %{conn: conn} do
  #     {:ok, view, _html} = live(conn, "/?platform_id=swiftui")

  #     assert view |> element("#cell-0-5") |> render() =~ "#000000"
  #     assert view |> element("#cell-1-5") |> render() =~ "#000000"

  #     assert view |> element("#cell-0-5") |> render_click()
  #     assert view |> element("#cell-1-5") |> render_click()

  #     assert view |> element("#cell-0-5") |> render() =~ "#FF0000"
  #     refute view |> element("#cell-0-5") |> render() =~ "#000000"

  #     assert view |> element("#cell-1-5") |> render() =~ "#FFC82F"
  #     refute view |> element("#cell-1-5") |> render() =~ "#000000"
  #   end
  # end
end
