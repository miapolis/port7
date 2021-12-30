defmodule Ports.Rumble.Board.Snapping do
  alias Harbor.Utils.SimpleId
  alias Ports.Rumble.Tile
  alias Ports.Rumble.Group
  alias Ports.Rumble.Board.Common

  @spec snap_new(Tile.t(), Tile.t(), integer(), Group.group_type(), any()) :: {%{}, %{}}
  def snap_new(tile, snap_to, snap_side, type, state) do
    group_id = SimpleId.gen(state.milestone.groups)

    updated_current =
      %{tile | group_id: group_id}
      |> change_pos_to_snap(snap_to, snap_side)

    updated_snap_to = %{snap_to | group_id: group_id}

    all_tiles =
      state.milestone.tiles
      |> Map.put(tile.id, updated_current)
      |> Map.put(snap_to.id, updated_snap_to)

    found =
      find_chaining_near(updated_current, snap_side, %{
        state
        | milestone: %{state.milestone | tiles: all_tiles}
      })

    children =
      if is_nil(found) do
        if snap_side == 0, do: [tile.id, snap_to.id], else: [snap_to.id, tile.id]
      else
        if snap_side == 0,
          do: [found.id, tile.id, snap_to.id],
          else: [snap_to.id, tile.id, found.id]
      end

    group = Common.create_group(group_id, children, type)

    all_tiles =
      case found do
        nil ->
          all_tiles

        _ ->
          Map.replace(all_tiles, found.id, %{found | group_id: group.id})
      end

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

    all_groups = Map.put(state.milestone.groups, group_id, group)

    {all_tiles, all_groups}
  end

  @spec snap_existing(Tile.t(), Tile.t(), integer(), any()) :: {%{}, %{}}
  def snap_existing(tile, snap_to, snap_side, state) do
    group = Map.get(state.milestone.groups, snap_to.group_id)
    snap_to_index = Enum.find_index(group.children, fn x -> x == snap_to.id end)
    index = if snap_side == 0, do: snap_to_index, else: snap_to_index + 1

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

  defp find_chaining_near(tile, snap_side, state) do
    tiles = state.milestone.tiles

    # The found tile isn't necessary valid to snap, it's just in the right location
    Enum.reduce_while(Map.values(tiles), nil, fn t, _ ->
      if t.y == tile.y and
           t.x == tile.x + if(snap_side == 0, do: -1 * Common.tile_width(), else: Common.tile_width()) do
        {:halt, t}
      else
        {:cont, nil}
      end
    end)
  end

  defp change_pos_to_snap(current, snap_to, snap_side) do
    x = if snap_side == 1, do: snap_to.x + Common.tile_width(), else: snap_to.x - Common.tile_width()
    y = snap_to.y
    %{current | x: x, y: y}
  end
end
