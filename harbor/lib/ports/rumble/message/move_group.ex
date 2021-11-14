defmodule Ports.Rumble.Message.MoveGroup do
  use Pier.Message.Cast

  @primary_key false
  embedded_schema do
    field(:id, :integer)
    field(:x, :integer)
    field(:y, :integer)
    field(:endMove, :boolean)
  end

  def changeset(initializer \\ %__MODULE__{}, data) do
    initializer
    |> cast(data, [:id, :x, :y, :endMove])
    |> validate_number(:id, less_than: 108, greater_than_or_equal_to: 0)
    |> validate_required([:x, :y])
  end

  def execute(changeset, state) do
    with {:ok, %{id: id, x: x, y: y, endMove: end_move}} <-
           apply_action(changeset, :validation) do

      Ports.Rumble.Game.move_group(state.user.current_room_id, state.user.peer_id, id, x, y, end_move)

      {:noreply, state}
    end
  end
end
