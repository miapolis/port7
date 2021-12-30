defmodule Ports.Rumble.Board.Common do
  alias Harbor.Utils.SimpleId
  alias Ports.Rumble.Tile
  alias Ports.Rumble.Group

  @tile_width 100
  def tile_width(), do: @tile_width
  @tile_height 130
  def tile_height(), do: @tile_height

  @spec can_snap_to(Tile.t(), Tile.t(), 0 | 1, any()) :: boolean()
  def can_snap_to(tile, snap_to, snap_side, state) do
    tiles = state.milestone.tiles
    groups = state.milestone.groups
    group = Map.get(groups, snap_to.group_id)

    case group.group_type do
      :set ->
        colors =
          Enum.reduce(group.children, [], fn x, acc ->
            tile = Map.get(tiles, x)
            [tile.data.color | acc]
          end)

        tile.data.value == snap_to.data.value and not Enum.member?(colors, tile.data.color)

      :run ->
        if tile.data.color == snap_to.data.color do
          if snap_side == 0,
            do: tile.data.value == snap_to.data.value - 1,
            else: tile.data.value == snap_to.data.value + 1
        else
          false
        end
    end
  end

  @spec can_create_group(Tile.t(), Tile.t()) :: {Group.group_type(), boolean()}
  def can_create_group(tile, snap_to) do
    if tile.data.color == snap_to.data.color do
      # Only snap if the tiles are consecutive values
      {:run, abs(tile.data.value - snap_to.data.value) == 1}
    else
      # They must be the same exact number
      {:set, tile.data.value == snap_to.data.value}
    end
  end

  def create_group(id, children, type) do
    %Group{
      id: id,
      children: children,
      group_type: type
    }
  end

  def set_iter_tiles(tiles, func) do
    Enum.reduce(Map.values(tiles), %{}, fn x, acc ->
      new = func.(x)
      Map.put(acc, x.id, new)
    end)
  end

  def get_group_influencer(group) do
    count = Enum.count(group.children)

    case rem(Enum.count(group.children), 2) do
      0 -> {:even, Enum.at(group.children, trunc(count / 2 - 1))}
      _ -> {:odd, Enum.at(group.children, trunc((count + 1) / 2 - 1))}
    end
  end

  def get_group_center(group, tiles) do
    case get_group_influencer(group) do
      {:even, id} ->
        tile = Map.get(tiles, id)
        {tile.x + @tile_width, tile.y + @tile_height}

      {:odd, id} ->
        tile = Map.get(tiles, id)
        {tile.x + @tile_width / 2, tile.y + @tile_height}
    end
  end
end
