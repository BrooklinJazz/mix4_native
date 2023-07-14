defmodule Connect4Web.ErrorJSONTest do
  use Connect4Web.ConnCase, async: true

  test "renders 404" do
    assert Connect4Web.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert Connect4Web.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
