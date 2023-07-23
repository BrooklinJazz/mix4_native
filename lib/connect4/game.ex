defmodule Connect4.Game do
  use GenServer
  require Logger

  defstruct [
    :winner,
    player1: nil,
    player2: nil,
    board: Connect4.initial_board(),
    current_turn: nil
  ]

  def start_link(opts) do
    name = Keyword.get(opts, :name)
    player1 = Keyword.fetch!(opts, :player1)
    player2 = Keyword.fetch!(opts, :player2)
    game = %__MODULE__{player1: player1, player2: player2, current_turn: player1}
    GenServer.start_link(__MODULE__, game, name: name)
  end

  def board(pid) do
    GenServer.call(pid, :board)
  end

  def drop(pid, player, column_index) do
    GenServer.call(pid, {:drop, player, column_index})
  end

  def game(pid) do
    GenServer.call(pid, :game)
  end

  def opponent(pid, player) do
    GenServer.call(pid, {:opponent, player})
  end

  def winner(pid) do
    GenServer.call(pid, :winner)
  end

  def init(game) do
    {:ok, game}
  end

  def handle_call(:board, _from, %__MODULE__{board: board} = game) do
    {:reply, board, game}
  end

  def handle_call(
        {:opponent, player},
        _from,
        %__MODULE__{player1: player1, player2: player2} = game
      ) do
    opponent =
      case player do
        ^player1 -> player2
        ^player2 -> player1
      end

    {:reply, opponent, game}
  end

  def handle_call({:drop, player, column_index}, _from, game) do
    if game.current_turn == player do
      updated_board = Connect4.drop(game.board, column_index, marker(game))

      game_winner =
        case Connect4.winner(updated_board) do
          :red -> game.player1
          :yellow -> game.player2
          nil -> nil
        end

      updated_game = %__MODULE__{
        game
        | winner: game_winner,
          board: updated_board,
          current_turn: switch_player(game)
      }

      Phoenix.PubSub.broadcast(Connect4.PubSub, "game", {:game_updated, updated_game})
      {:reply, :ok, updated_game}
    else
      {:reply, :error, game}
    end
  end

  def handle_call(:winner, _from, game) do
    {:reply, game.winner, game}
  end

  def handle_call(:game, _from, game) do
    {:reply, game, game}
  end

  defp switch_player(%__MODULE__{player1: player1, player2: player2, current_turn: current_turn}) do
    case current_turn do
      ^player1 -> player2
      ^player2 -> player1
    end
  end

  defp marker(%__MODULE__{player1: player1, player2: player2, current_turn: current_turn}) do
    case current_turn do
      ^player1 -> :red
      ^player2 -> :yellow
    end
  end
end
