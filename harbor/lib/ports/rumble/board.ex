defmodule Ports.Rumble.Board do
  alias Harbor.Utils.SimpleId
  alias Ports.Rumble.Tile
  alias Ports.Rumble.Group

  @tile_width 100
  @tile_height 130

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

  def move_end_tile(tile, tile_index, group, state) do
    new_children = List.delete_at(group.children, tile_index)

    Anchorage.RoomSession.broadcast_ws(state.room_id, %{
      op: "update_group",
      d: %{
        group: %{group | children: new_children},
        remove: tile.id
      }
    })

    updated_tile = %{tile | group_id: nil}
    updated_group = %{group | children: new_children}

    {Map.put(state.milestone.tiles, tile.id, updated_tile),
     Map.put(state.milestone.groups, group.id, updated_group)}
  end

  def move_middle_tile(tile, tile_index, group, state) do
    new_children = List.delete_at(group.children, tile_index)
    {left, right} = Enum.split(new_children, tile_index)
    IO.puts("LEFT: " <> inspect(left) <> ", RIGHT: " <> inspect(right))

    {left_invalid, right_invalid} = {Enum.count(left) <= 1, Enum.count(right) <= 1}

    {original_group, new_group, to_delete} =
      if left_invalid or right_invalid do
        cond do
          left_invalid and right_invalid ->
            # Destroy the original group
            {nil, nil, nil}

          left_invalid ->
            {%{group | children: right}, nil, left}

          right_invalid ->
            {%{group | children: left}, nil, right}
        end
      else
        # Groups have been split and a new group must be created
        # The original group will be the left, and the new group will be the right
        original = %{group | children: left}
        new = create_group(SimpleId.gen(state.milestone.groups), right)
        {original, new, nil}
      end

    {all_tiles, all_groups} =
      unless is_nil(new_group) do
        Anchorage.RoomSession.broadcast_ws(state.room_id, %{
          op: "mass_update_groups",
          d: %{
            groups: [original_group, new_group]
          }
        })

        new_tiles = Map.take(state.milestone.tiles, new_group.children)
        updated_tiles = set_iter_tiles(new_tiles, fn x -> %{x | group_id: new_group.id} end)

        groups =
          state.milestone.groups
          |> Map.put(group.id, original_group)
          |> Map.put(new_group.id, new_group)

        {Map.merge(state.milestone.tiles, updated_tiles), groups}
      else
        if is_nil(original_group) do
          Anchorage.RoomSession.broadcast_ws(state.room_id, %{
            op: "delete_group",
            d: %{
              id: group.id
            }
          })

          to_delete_tiles = Map.take(state.milestone.tiles, group.children)
          updated_tiles = set_iter_tiles(to_delete_tiles, fn x -> %{x | group_id: nil} end)

          {Map.merge(state.milestone.tiles, updated_tiles),
           Map.delete(state.milestone.groups, group.id)}
        else
          Anchorage.RoomSession.broadcast_ws(state.room_id, %{
            op: "update_group",
            d: %{group: original_group, strict: true}
          })

          to_delete_tiles = Map.take(state.milestone.tiles, to_delete)

          updated_tiles =
            set_iter_tiles(to_delete_tiles, fn x ->
              %{x | group_id: nil}
            end)

          {Map.merge(state.milestone.tiles, updated_tiles),
           Map.put(state.milestone.groups, original_group.id, original_group)}
        end
      end

    {Map.put(all_tiles, tile.id, %{tile | group_id: nil}), all_groups}
  end

  ### - SNAPPING - ###########################################################

  @spec snap_new(Tile.t(), Tile.t(), integer(), any()) :: {%{}, %{}}
  def snap_new(tile, snap_to, snap_side, state) do
    group_id = SimpleId.gen(state.milestone.groups)

    updated_current =
      %{tile | group_id: group_id}
      |> change_pos_to_snap(snap_to, snap_side)

    updated_snap_to = %{snap_to | group_id: group_id}
    children = if snap_side == 0, do: [tile.id, snap_to.id], else: [snap_to.id, tile.id]
    IO.puts("CREATED CHILDREN" <> inspect(children))

    group = create_group(group_id, children)

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
    index = if snap_side == 0, do: snap_to_index, else: snap_to_index + 1

    children = List.insert_at(group.children, index, tile.id)
    IO.puts("CHILDREN AFTER SNAP " <> inspect(children))
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

  @spec overlaps_any(number(), number(), %{any() => Tile.t()}) :: boolean()
  def overlaps_any(x, y, tiles) do
    Enum.reduce_while(Map.values(tiles), false, fn tile, _acc ->
      if x_overlap(tile.x, x) && y_overlap(tile.y, y) do
        {:halt, true}
      else
        {:cont, false}
      end
    end)
  end

  defp x_overlap(one, two) do
    Kernel.abs(one - two) < @tile_width
  end

  defp y_overlap(one, two) do
    Kernel.abs(one - two) < @tile_height
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
