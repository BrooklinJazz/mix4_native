defmodule Connect4.Games do
  require Logger

  alias Connect4.Games.Game
  alias Connect4.Games.Player
  defstruct active_games: %{}, queue: []

  def new() do
    %__MODULE__{}
  end

  def find_game_by_id(%__MODULE__{active_games: active_games}, game_id) do
    Map.get(active_games, game_id)
  end

  def find_game_by_player(%__MODULE__{active_games: active_games}, %Player{} = player) do
    Enum.reduce_while(active_games, nil, fn {_, game}, acc ->
      if game.player1 == player || game.player2 == player do
        {:halt, game}
      else
        {:cont, acc}
      end
    end)
  end

  def join(%__MODULE__{} = games, %Player{} = player) do
    existing_game = find_game_by_player(games, player)

    cond do
      existing_game && Game.finished?(existing_game) ->
        active_games = Map.delete(games.active_games, existing_game.id)
        join(%__MODULE__{games | active_games: active_games}, player)

      # ignore if player is already in a game
      existing_game ->
        {:ignored, games}

      Enum.any?(games.queue) ->
        game = Game.new(player, hd(games.queue))

        games =
          games
          |> Map.put(:queue, tl(games.queue))
          |> Map.put(:active_games, Map.put(games.active_games, game.id, game))

        {:game_started, games}

      Enum.empty?(games.queue) ->
        {:enqueued, %__MODULE__{games | queue: [player]}}
    end
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
end
