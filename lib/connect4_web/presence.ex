defmodule Connect4Web.Presence do
  use Phoenix.Presence,
    otp_app: :connect4,
    pubsub_server: Connect4.PubSub
end
