defmodule Connect4.GameQueue do
  use GenServer
  alias Connect4.Game
  defstruct waiting_players: []

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    {:ok, %__MODULE__{}}
  end

  def join(player) do
    Phoenix.PubSub.subscribe(Connect4.PubSub, "game")
    GenServer.call(__MODULE__, {:join, player})
  end

  def handle_call({:join, player1}, _from, %__MODULE__{waiting_players: []} = state) do
    {:reply, :ok, %__MODULE__{state | waiting_players: [player1]}}
  end

  def handle_call({:join, player2}, _from, %__MODULE__{waiting_players: [player1]} = state) do
    game_id = Ecto.UUID.autogenerate()
    name = {:via, Registry, {Connect4.GameRegistry, game_id}}
    {:ok, pid} = Game.start_link(id: game_id, player1: player1, player2: player2, name: name)
    Phoenix.PubSub.broadcast(Connect4.PubSub, "game", {:game_started, pid})
    {:reply, :ok, %__MODULE__{state | waiting_players: []}}
  end
end
