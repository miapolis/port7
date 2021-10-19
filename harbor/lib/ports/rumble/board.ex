defmodule Ports.Rumble.Board do
  alias Harbor.Utils.SimpleId
  alias Ports.Rumble.Tile
  alias Ports.Rumble.Group

  @tile_width 100

  @spec snap_new(Tile.t(), Tile.t(), integer(), any()) :: {%{}, %{}}
  def snap_new(tile, snap_to, snap_side, state) do
    group_id = SimpleId.gen(state.groups)

    updated_current =
      %{tile | group_id: group_id}
      |> change_pos_to_snap(snap_to, snap_side)

    updated_snap_to = %{snap_to | group_id: group_id}

    group = create_group(group_id, %{snap_side => tile.id, (1 - snap_side) => snap_to.id})

    Anchorage.RoomSession.broadcast_ws(
      state.room_id,
      %{
        op: "tile_snapped",
        d: %{
          id: tile.id,
          snapTo: snap_to.id,
          snapSide: snap_side,
          group: group
        }
      }
    )

    all_tiles =
      state.tiles
      |> Map.put(tile.id, updated_current)
      |> Map.put(snap_to.id, updated_snap_to)

    all_groups = Map.put(state.groups, group_id, group)

    {all_tiles, all_groups}
  end

  defp create_group(id, children) do
    %Group{
      id: id,
      children: children,
      group_type: :set
    }
  end

  defp change_pos_to_snap(current, snap_to, snap_side) do
    x = if snap_side == 1, do: snap_to.x + @tile_width, else: snap_to.x - @tile_width
    y = snap_to.y
    %{current | x: x, y: y}
  end
end
