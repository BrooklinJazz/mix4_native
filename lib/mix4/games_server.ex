defmodule Mix4.GamesServer do
  use GenServer
  alias Mix4.Games
  alias Mix4.Games.Game

  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, [], name: name)
  end

  def init(_opts) do
    {:ok, Games.new()}
  end

  def drop(pid \\ __MODULE__, game_id, player, column_index) do
    GenServer.call(pid, {:drop, game_id, player, column_index})
  end

  def find_game_by_player(pid \\ __MODULE__, player) do
    GenServer.call(pid, {:find_game_by_player, player})
  end

  def find_game_by_id(pid \\ __MODULE__, id) do
    GenServer.call(pid, {:find_game_by_id, id})
  end

  def incoming_requests(pid \\ __MODULE__, player) do
    GenServer.call(pid, {:incoming_requests, player})
  end

  def join_queue(pid \\ __MODULE__, player) do
    GenServer.call(pid, {:join_queue, player})
  end

  def leave_queue(pid \\ __MODULE__, player) do
    GenServer.call(pid, {:leave_queue, player})
  end

  def outgoing_requests(pid \\ __MODULE__, player) do
    GenServer.call(pid, {:outgoing_requests, player})
  end

  def quit(pid \\ __MODULE__, player) do
    GenServer.call(pid, {:quit, player})
  end

  def request(pid \\ __MODULE__, requester, requested) do
    GenServer.call(pid, {:request, requester, requested})
  end

  def update(pid \\ __MODULE__, updated_game) do
    GenServer.call(pid, {:update, updated_game})
  end

  def waiting?(pid \\ __MODULE__, player) do
    GenServer.call(pid, {:waiting, player})
  end

  def wipe(pid \\ __MODULE__) do
    GenServer.call(pid, :wipe)
  end

  def handle_call({:find_game_by_player, player}, _from, games) do
    {:reply, Games.find_game_by_player(games, player), games}
  end

  def handle_call({:find_game_by_id, game_id}, _from, games) do
    {:reply, Games.find_game_by_id(games, game_id), games}
  end

  def handle_call({:drop, game_id, player, column_index}, _from, games) do
    game = Games.find_game_by_id(games, game_id)

    if game do
      updated_game = Game.drop(game, player, column_index)

      Phoenix.PubSub.broadcast(
        Mix4.PubSub,
        "game:#{updated_game.id}",
        {:game_updated, updated_game}
      )

      {:reply, :ok, Games.update(games, updated_game)}
    else
      {:reply, :error, games}
    end
  end

  def handle_call({:incoming_requests, player}, _from, games) do
    {:reply, Games.incoming_requests(games, player), games}
  end

  def handle_call({:join_queue, player}, _from, games) do
    case Games.join_queue(games, player) do
      {:enqueued, games} ->
        {:reply, :ok, games}

      {:ignored, games} ->
        {:reply, :error, games}

      {:game_started, games} ->
        broadcast_new_game(Games.find_game_by_player(games, player))
        {:reply, :ok, games}
    end
  end

  def handle_call({:leave_queue, player}, _from, games) do
    {:reply, :ok, Games.leave_queue(games, player)}
  end

  def handle_call({:outgoing_requests, player}, _from, games) do
    {:reply, Games.outgoing_requests(games, player), games}
  end

  def handle_call({:quit, player}, _from, games) do
    game = Games.find_game_by_player(games, player)

    if game && !Game.winner(game) do
      Phoenix.PubSub.broadcast(Mix4.PubSub, "game:#{game.id}", {:game_quit, player})
    end

    {:ok, games} = Games.quit(games, player)
    {:reply, :ok, games}
  end

  def handle_call({:request, requester, requested}, _from, games) do
    case Games.request(games, requester, requested) do
      {:requested, games} ->
        Phoenix.PubSub.broadcast(
          Mix4.PubSub,
          "player:#{requested.id}",
          {:game_requested, requester}
        )

        {:reply, :ok, games}

      {:ignored, games} ->
        {:reply, :error, games}

      {:game_started, games} ->
        broadcast_new_game(Games.find_game_by_player(games, requester))
        {:reply, :ok, games}
    end
  end

  def handle_call({:update, updated_game}, _from, games) do
    Phoenix.PubSub.broadcast(
      Mix4.PubSub,
      "game:#{updated_game.id}",
      {:game_updated, updated_game}
    )

    {:reply, :ok, Games.update(games, updated_game)}
  end

  def handle_call({:waiting, player}, _from, games) do
    {:reply, Games.waiting?(games, player), games}
  end

  def handle_call(:wipe, _from, _games) do
    {:reply, :ok, Games.new()}
  end

  defp broadcast_new_game(new_game) do
    player1 = Game.player1(new_game)
    player2 = Game.player2(new_game)

    Phoenix.PubSub.broadcast(
      Mix4.PubSub,
      "player:#{player1.id}",
      {:game_started, new_game}
    )

    Phoenix.PubSub.broadcast(
      Mix4.PubSub,
      "player:#{player2.id}",
      {:game_started, new_game}
    )
  end
end
