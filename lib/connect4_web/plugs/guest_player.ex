defmodule Connect4Web.Plugs.GuestPlayer do
  alias Connect4.Player
  def init(default), do: default

  def call(conn, _params) do
    # if the player changes, the session might use an old invalid value.
    case Plug.Conn.get_session(conn, :current_player) |> IO.inspect(label: "SESSION PLAYER") do
      nil ->
        Plug.Conn.put_session(conn, :current_player, %Player{
          id: Ecto.UUID.autogenerate(),
          name: Enum.random(["fluffy", "tiger", "koala", "howard"])
        })

      _ ->
        conn
    end
  end
end
