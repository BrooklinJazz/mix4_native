defmodule Connect4Web.Connect4LiveTest do
  use Connect4Web.ConnCase

  test "connected mount", %{conn: conn} do
    {:ok, view, html} = live(conn, "/")
    assert html =~ "Connect4"
  end
end
