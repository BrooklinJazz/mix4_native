defmodule Mix4.Games do
  require Logger

  alias Mix4.Games.Game
  alias Mix4.Games.Player
  defstruct active_games: %{}, queue: [], requests: []

  def new() do
    %__MODULE__{}
  end

  def find_game_by_id(%__MODULE__{active_games: active_games}, game_id) do
    Map.get(active_games, game_id)
  end

  def find_game_by_player(%__MODULE__{active_games: active_games}, %Player{} = player) do
    Enum.find_value(active_games, fn {_, game} ->
      if player.id in [game.player1.id, game.player2.id], do: game
    end)
  end

  def incoming_requests(%__MODULE__{} = games, %Player{} = player) do
    Enum.reduce(games.requests, [], fn {requester, requested}, acc ->
      if requested == player, do: [requester | acc], else: acc
    end)
  end

  def join_queue(%__MODULE__{} = games, %Player{} = player) do
    existing_game = find_game_by_player(games, player)
    should_cleanup_game = existing_game && Game.finished?(existing_game)

    cond do
      should_cleanup_game ->
        games
        |> remove_game(existing_game)
        |> join_queue(player)

      # ignore if player is already in a game
      existing_game ->
        {:ignored, games}

      player in games.queue ->
        {:ignored, games}

      Enum.any?(games.queue) ->
        waiting_player = hd(games.queue)

        {:game_started,
         games
         |> remove_from_queue(waiting_player)
         |> add_game(Game.new(player, waiting_player))}

      Enum.empty?(games.queue) ->
        {:enqueued, %__MODULE__{games | queue: [player]}}
    end
  end

  def leave_queue(%__MODULE__{} = games, %Player{} = player) do
    %__MODULE__{games | queue: Enum.reject(games.queue, &(&1.id == player.id))}
  end

  def outgoing_requests(%__MODULE__{} = games, %Player{} = player) do
    Enum.reduce(games.requests, [], fn {requester, requested}, acc ->
      if requester == player, do: [requested | acc], else: acc
    end)
  end

  def queue(%__MODULE__{queue: queue}), do: queue

  def update(%__MODULE__{active_games: active_games} = games, %Game{} = game) do
    %__MODULE__{games | active_games: Map.put(active_games, game.id, game)}
  end

  def waiting?(%__MODULE__{queue: queue}, %Player{} = player) do
    player in queue
  end

  def quit(%__MODULE__{} = games, %Player{} = player) do
    game = find_game_by_player(games, player)

    if game do
      games = %__MODULE__{games | active_games: Map.delete(games.active_games, game.id)}
      {:ok, games}
    else
      {:ok, games}
    end
  end

  def request(%__MODULE__{} = games, %Player{} = requester, %Player{} = requested) do
    game = find_game_by_player(games, requester) || find_game_by_player(games, requested)

    cond do
      game ->
        {:ignored, games}

      # if both players request a game
      {requested, requester} in games.requests ->
        {:game_started,
         games
         |> add_game(Game.new(requester, requested))
         |> remove_request({requested, requester})
         |> remove_request({requester, requested})}

      # ignore duplicate requests
      {requester, requested} in games.requests ->
        {:ignored, games}

      true ->
        {:requested, games |> add_request(requester, requested)}
    end
  end

  defp add_game(games, game) do
    %__MODULE__{games | active_games: Map.put(games.active_games, game.id, game)}
  end

  defp remove_game(games, game) do
    %__MODULE__{games | active_games: Map.delete(games.active_games, game.id)}
  end

  defp add_request(games, requester, requested) do
    %__MODULE__{games | requests: [{requester, requested} | games.requests]}
  end

  defp remove_request(games, {requester, requested}) do
    %__MODULE__{games | requests: games.requests |> List.delete({requester, requested})}
  end

  defp remove_from_queue(games, player) do
    %__MODULE__{games | queue: Enum.reject(games.queue, &(&1.id == player.id))}
  end
end
