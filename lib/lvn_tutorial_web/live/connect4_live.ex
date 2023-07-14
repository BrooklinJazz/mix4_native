defmodule LvnTutorialWeb.Connect4Live do
  use LvnTutorialWeb, :live_view
  use LiveViewNative.LiveView

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(%{platform_id: :web} = assigns) do
    ~H""
  end

  def render(%{platform_id: :swiftui} = assigns) do
    ~Z"""
    <Text>Hello, world!</Text>
    """swiftui
  end
end
