defmodule Mix4Web.ErrorJSONTest do
  use Mix4Web.ConnCase, async: true

  test "renders 404" do
    assert Mix4Web.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert Mix4Web.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
