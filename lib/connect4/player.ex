defmodule Connect4.Player do
  defstruct [:id, :name]

  def new(id \\ Ecto.UUID.autogenerate(), name \\ Enum.random(["pixie", "hubert", "derl"])) do
    %__MODULE__{id: id, name: name}
  end
end
