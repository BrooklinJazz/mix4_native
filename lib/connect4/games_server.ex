defmodule Connect4.GamesServer do
  use GenServer
  alias Connect4.Games
  alias Connect4.Games.Game

  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, [], name: name)
  end

  def init(_opts) do
    {:ok, Games.new()}
  end

  def find_game(pid \\ __MODULE__, player) do
    GenServer.call(pid, {:find_game, player})
  end

  def join(pid \\ __MODULE__, player) do
    GenServer.call(pid, {:join, player})
  end

  def update(pid \\ __MODULE__, updated_game) do
    GenServer.call(pid, {:update, updated_game})
  end

  def waiting?(pid \\ __MODULE__, player) do
    GenServer.call(pid, {:waiting, player})
  end

  def handle_call({:find_game, player}, _from, games) do
    {:reply, Games.find_game(games, player), games}
  end

  def handle_call({:join, player}, _from, games) do
    existing_game = Games.find_game(games, player)
    updated_games = Games.join(games, player)
    new_game = Games.find_game(updated_games, player)

    cond do
      existing_game ->
        {:reply, :error, games}

      new_game ->
        broadcast_new_game(new_game)

        {:reply, :ok, updated_games}

      true ->
        {:reply, :ok, updated_games}
    end
  end

  def handle_call({:update, updated_game}, _from, games) do
    Phoenix.PubSub.broadcast(
      Connect4.PubSub,
      "game:#{updated_game.id}",
      {:game_updated, updated_game}
    )

    {:reply, :ok, Games.update(games, updated_game)}
  end

  def handle_call({:waiting, player}, _from, games) do
    {:reply, Games.waiting?(games, player), games}
  end

  defp broadcast_new_game(new_game) do
    player1 = Game.player1(new_game)
    player2 = Game.player2(new_game)
    Phoenix.PubSub.broadcast(Connect4.PubSub, "player:#{player1.id}", {:game_started, new_game})
    Phoenix.PubSub.broadcast(Connect4.PubSub, "player:#{player2.id}", {:game_started, new_game})
  end
end
