defmodule Ports.Rumble.Board do
  alias Harbor.Utils.SimpleId
  alias Ports.Rumble.Tile
  alias Ports.Rumble.Group

  @tile_width 100

  ### - MOVING - #############################################################

  @spec move_to_delete_group(Tile.t(), Group.t(), any()) :: {%{}, %{}}
  def move_to_delete_group(_tile, group, state) do
    tiles = Map.take(state.milestone.tiles, group.children)
    cleared_tiles = set_iter_tiles(tiles, fn x -> %{x | group_id: nil} end)
    groups = Map.delete(state.milestone.groups, group.id)

    Anchorage.RoomSession.broadcast_ws(state.room_id, %{
      op: "delete_group",
      d: %{
        id: group.id
      }
    })

    {Map.merge(state.milestone.tiles, cleared_tiles), groups}
  end

  ### - SNAPPING - ###########################################################

  @spec snap_new(Tile.t(), Tile.t(), integer(), any()) :: {%{}, %{}}
  def snap_new(tile, snap_to, snap_side, state) do
    group_id = SimpleId.gen(state.milestone.groups)

    updated_current =
      %{tile | group_id: group_id}
      |> change_pos_to_snap(snap_to, snap_side)

    updated_snap_to = %{snap_to | group_id: group_id}

    group = create_group(group_id, [tile.id, snap_to.id])

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
      state.milestone.tiles
      |> Map.put(tile.id, updated_current)
      |> Map.put(snap_to.id, updated_snap_to)

    all_groups = Map.put(state.milestone.groups, group_id, group)

    {all_tiles, all_groups}
  end

  @spec snap_existing(Tile.t(), Tile.t(), integer(), any()) :: {%{}, %{}}
  def snap_existing(tile, snap_to, snap_side, state) do
    group = Map.get(state.milestone.groups, snap_to.group_id)
    snap_to_index = Enum.find_index(group.children, fn x -> x == snap_to.id end)
    index = if snap_side === 1, do: snap_to_index + 1, else: snap_to_index - 1

    children = List.insert_at(group.children, index, tile.id)
    updated_group = %{group | children: children}

    updated_current =
      %{tile | group_id: group.id}
      |> change_pos_to_snap(snap_to, snap_side)

    Anchorage.RoomSession.broadcast_ws(
      state.room_id,
      %{
        op: "tile_snapped",
        d: %{
          id: tile.id,
          snapTo: snap_to.id,
          snapSide: snap_side,
          group: updated_group
        }
      }
    )

    all_tiles =
      state.milestone.tiles
      |> Map.put(tile.id, updated_current)

    all_groups = Map.put(state.milestone.groups, group.id, updated_group)

    {all_tiles, all_groups}
  end

  defp create_group(id, children) do
    %Group{
      id: id,
      children: children,
      group_type: :set
    }
  end

  defp set_iter_tiles(tiles, func) do
    Enum.reduce(Map.values(tiles), %{}, fn x, acc ->
      new = func.(x)
      Map.put(acc, x.id, new)
    end)
  end

  defp change_pos_to_snap(current, snap_to, snap_side) do
    x = if snap_side == 1, do: snap_to.x + @tile_width, else: snap_to.x - @tile_width
    y = snap_to.y
    %{current | x: x, y: y}
  end
end
