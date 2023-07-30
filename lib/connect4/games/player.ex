defmodule Connect4.Games.Player do
  @enforce_keys [:id, :name]
  defstruct @enforce_keys

  def new(fields \\ []) do
    fields =
      Enum.into(fields, %{
        id: Ecto.UUID.autogenerate(),
        name: Enum.random(["pixie", "hubert", "derl"])
      })

    struct(__MODULE__, fields)
  end
end
