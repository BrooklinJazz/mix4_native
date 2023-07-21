defmodule Connect4Web.Connect4LiveTest do
  use Connect4Web.ConnCase, async: true

  setup do
    on_exit(fn -> Application.put_env(:connect4, :platform_id, :web) end)
    :ok
  end

  test "connected mount", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/")

    assert html =~ "Connect4"
  end

  test "connected mount - render board", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    assert view |> element("#board")

    # 7 columns
    Enum.each(0..6, fn i ->
      assert has_element?(view, "#column-#{i}")
    end)
  end

  test "players can drop discs", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    assert view |> element("#cell-0-5") |> render() =~ "bg-black"
    assert view |> element("#cell-1-5") |> render() =~ "bg-black"

    view |> element("#column-0") |> render_click()
    assert view |> element("#cell-0-5") |> render() =~ "bg-red-400"

    view |> element("#column-1") |> render_click()
    assert view |> element("#cell-1-5") |> render() =~ "bg-yellow-400"
  end

  test "player 1 can win", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    view |> element("#column-0") |> render_click()
    view |> element("#column-1") |> render_click()
    view |> element("#column-0") |> render_click()
    view |> element("#column-1") |> render_click()
    view |> element("#column-0") |> render_click()
    view |> element("#column-1") |> render_click()
    view |> element("#column-0") |> render_click()

    assert view |> render() =~ "red wins!"
  end

  test "player 2 can win", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    view |> element("#column-0") |> render_click()
    view |> element("#column-2") |> render_click()
    view |> element("#column-1") |> render_click()
    view |> element("#column-2") |> render_click()
    view |> element("#column-0") |> render_click()
    view |> element("#column-2") |> render_click()
    view |> element("#column-1") |> render_click()
    view |> element("#column-2") |> render_click()

    assert view |> render() =~ "yellow wins!"
  end

  describe "swiftui" do
    test "render the board", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/?platform_id=swiftui")
      assert view |> has_element?("#board")
    end

    test "players can drop disc", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/?platform_id=swiftui")

      assert view |> element("#cell-0-5") |> render() =~ "#000000"
      assert view |> element("#cell-1-5") |> render() =~ "#000000"

      assert view |> element("#cell-0-5") |> render_click()
      assert view |> element("#cell-1-5") |> render_click()

      assert view |> element("#cell-0-5") |> render() =~ "#FF0000"
      refute view |> element("#cell-0-5") |> render() =~ "#000000"

      assert view |> element("#cell-1-5") |> render() =~ "#FFC82F"
      refute view |> element("#cell-1-5") |> render() =~ "#000000"
    end
  end
end
