defmodule Ports.Rumble.Board.Moving do
  alias Harbor.Utils.SimpleId
  alias Ports.Rumble.Tile
  alias Ports.Rumble.Group
  alias Ports.Rumble.Board.Common

  @spec move_to_delete_group(Tile.t(), Group.t(), any()) :: {%{}, %{}}
  def move_to_delete_group(_tile, group, state) do
    tiles = Map.take(state.milestone.tiles, group.children)
    cleared_tiles = Common.set_iter_tiles(tiles, fn x -> %{x | group_id: nil} end)
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
        new = Common.create_group(SimpleId.gen(state.milestone.groups), right, group.group_type)
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
        updated_tiles = Common.set_iter_tiles(new_tiles, fn x -> %{x | group_id: new_group.id} end)

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
          updated_tiles = Common.set_iter_tiles(to_delete_tiles, fn x -> %{x | group_id: nil} end)

          {Map.merge(state.milestone.tiles, updated_tiles),
           Map.delete(state.milestone.groups, group.id)}
        else
          Anchorage.RoomSession.broadcast_ws(state.room_id, %{
            op: "update_group",
            d: %{group: original_group, strict: true}
          })

          to_delete_tiles = Map.take(state.milestone.tiles, to_delete)

          updated_tiles =
            Common.set_iter_tiles(to_delete_tiles, fn x ->
              %{x | group_id: nil}
            end)

          {Map.merge(state.milestone.tiles, updated_tiles),
           Map.put(state.milestone.groups, original_group.id, original_group)}
        end
      end

    {Map.put(all_tiles, tile.id, %{tile | group_id: nil}), all_groups}
  end

  def move_group(peer_id, group, x, y, end_move, state) do
    {current_x, current_y} = Common.get_group_center(group, state.milestone.tiles)
    {delta_x, delta_y} = {x - current_x, y - current_y}

    affected_tiles = Map.take(state.milestone.tiles, group.children)

    updated_tiles =
      for {id, tile} <- affected_tiles,
          into: %{},
          do: {id, %{tile | x: tile.x + delta_x, y: tile.y + delta_y}}

    to_send =
      for {id, tile} <- updated_tiles,
          into: %{},
          do: {id, %{x: tile.x, y: tile.y}}

    Anchorage.RoomSession.broadcast_ws(
      state.room_id,
      %{
        op: "group_moved",
        d: %{
          group: group,
          positions: to_send,
          endMove: end_move
        }
      },
      except: peer_id
    )

    {Map.merge(state.milestone.tiles, updated_tiles), state.milestone.groups}
  end
end
