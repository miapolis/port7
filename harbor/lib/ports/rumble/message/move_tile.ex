defmodule Ports.Rumble.Message.MoveTile do
  use Pier.Message.Cast

  @primary_key false
  embedded_schema do
    field(:id, :integer)
    field(:x, :integer)
    field(:y, :integer)
  end

  def changeset(initializer \\ %__MODULE__{}, data) do
    initializer
    |> cast(data, [:id, :x, :y])
    |> validate_number(:id, less_than: 108, greater_than_or_equal_to: 0)
  end

  def execute(changeset, state) do
    with {:ok, %{id: id, x: x, y: y}} <- apply_action(changeset, :validation) do
      Ports.Rumble.Game.move_tile(state.user.current_room_id, state.user.peer_id, id, x, y)
      {:noreply, state}
    end
  end
end
