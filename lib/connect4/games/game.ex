defmodule Connect4.Games.Game do
  require Logger
  alias Connect4.Games.Board

  defstruct [
    :id,
    :winner,
    player1: nil,
    player2: nil,
    board: Board.new(),
    current_turn: nil
  ]

  def new(playera, playerb) do
    [player1, player2] = Enum.shuffle([playera, playerb])

    %__MODULE__{
      id: Ecto.UUID.autogenerate(),
      player1: player1,
      player2: player2,
      current_turn: player1
    }
  end

  def board(%__MODULE__{} = game), do: game.board
  def current_turn(%__MODULE__{} = game), do: game.current_turn

  def drop(%__MODULE__{} = game, player, column_index) do
    if game.current_turn == player do
      board = Board.drop(game.board, column_index, marker(game, player))

      game_winner =
        case Board.winner(board) do
          nil -> nil
          :red -> game.player1
          :yellow -> game.player2
        end

      %__MODULE__{game | board: board, current_turn: next_player(game), winner: game_winner}
    else
      game
    end
  end

  def finished?(%__MODULE__{} = game), do: game.winner != nil

  def marker(%__MODULE__{player1: player1, player2: player2}, player) do
    case player do
      ^player1 -> :red
      ^player2 -> :yellow
    end
  end

  def next_player(%__MODULE__{player1: player1, player2: player2, current_turn: current_turn}) do
    case current_turn do
      ^player1 -> player2
      ^player2 -> player1
    end
  end

  def player1(%__MODULE__{} = game), do: game.player1
  def player2(%__MODULE__{} = game), do: game.player2

  def opponent(%__MODULE__{player1: player1, player2: player2}, current_player) do
    case current_player do
      ^player1 -> player2
      ^player2 -> player1
    end
  end

  def winner(%__MODULE__{} = game), do: game.winner
end
