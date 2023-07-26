defmodule Connect4.Games do
  require Logger

  alias Connect4.Games.Game
  alias Connect4.Games.Player
  defstruct active_games: %{}, queue: []

  def new() do
    %__MODULE__{}
  end

  def join(%__MODULE__{queue: []} = games, %Player{} = player) do
    %__MODULE__{games | queue: [player]}
  end

  def join(%__MODULE__{queue: [playera], active_games: active_games} = games, %Player{} = playerb) do
    [player1, player2] = Enum.shuffle([playera, playerb])
    game = Game.new(player1, player2)
    %__MODULE__{games | queue: [], active_games: Map.put(active_games, game.id, game)}
  end

  def queue(%__MODULE__{queue: queue}), do: queue

  def find_game(%__MODULE__{active_games: active_games}, %Player{} = player) do
    Enum.reduce_while(active_games, nil, fn {_, game}, acc ->
      if game.player1 == player || game.player2 == player do
        {:halt, game}
      else
        {:cont, acc}
      end
    end)
  end

  def update(%__MODULE__{active_games: active_games} = games, %Game{} = game) do
    %__MODULE__{games | active_games: Map.put(active_games, game.id, game)}
  end

  def waiting?(%__MODULE__{queue: queue}, %Player{} = player) do
    player in queue
  end
end
