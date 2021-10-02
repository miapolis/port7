defmodule Ports.Rumble.Message.MoveTile do
  use Pier.Message.Cast

  @primary_key false
  embedded_schema do
    field(:id, :integer)
    field(:x, :integer)
    field(:y, :integer)
    field(:snapTo, :integer)
    field(:snapSide, :integer)
  end

  @spec changeset(
          {map, map}
          | %{
              :__struct__ => atom | %{:__changeset__ => map, optional(any) => any},
              optional(atom) => any
            },
          :invalid | %{optional(:__struct__) => none, optional(atom | binary) => any}
        ) :: Ecto.Changeset.t()
  def changeset(initializer \\ %__MODULE__{}, data) do
    initializer
    |> cast(data, [:id, :x, :y, :snapTo, :snapSide])
    |> validate_number(:id, less_than: 108, greater_than_or_equal_to: 0)
    |> validate_required([:x, :y])
  end

  def execute(changeset, state) do
    with {:ok, %{id: id, x: x, y: y, snapTo: snap_to, snapSide: snap_side}} <-
           apply_action(changeset, :validation) do
      case snap_to do
        nil ->
          Ports.Rumble.Game.move_tile(state.user.current_room_id, state.user.peer_id, id, x, y)

        _ ->
          if snap_side == 0 || snap_side == 1 do
            Ports.Rumble.Game.snap_to(
              state.user.current_room_id,
              state.user.peer_id,
              id,
              snap_to,
              snap_side
            )
          end
      end

      {:noreply, state}
    end
  end
end
