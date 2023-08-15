defmodule Mix4Web.Presence do
  use Phoenix.Presence,
    otp_app: :mix4,
    pubsub_server: Mix4.PubSub

  alias Mix4.Games.Player

  @players_topic "players"
  def players_topic, do: @players_topic

  def track_player(pid, %Player{} = player, game_id) do
    track(pid, @players_topic, player.id, %{
      struct: player,
      game_id: game_id
    })
  end

  def track_in_game(pid, %Player{} = player, game_id) do
    update(pid, @players_topic, player.id, fn player ->
      Map.put(player, :game_id, game_id)
    end)
  end

  def players do
    list(@players_topic)
    |> Enum.map(fn {user_id, _data} ->
      # I'm not sure if getting the last meta is a good idea
      # It might be better to only store the most recent meta in the Presence state somehow.
      # But I'm unfamiliar with Presence best practices and this will work for small scale.
      get_by_key(@players_topic, user_id)[:metas] |> List.last()
    end)
  end
end
