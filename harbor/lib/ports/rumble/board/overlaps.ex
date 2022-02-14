defmodule Ports.Rumble.Board.Overlaps do
  alias Ports.Rumble.Tile
  alias Ports.Rumble.Board.Common

  @fix_overlap_precision 30
  def fix_overlap_precision(), do: @fix_overlap_precision

  @spec overlaps_any(number(), number(), %{any() => Tile.t()}) :: any()
  def overlaps_any(x, y, tiles) do
    Enum.reduce_while(Map.values(tiles), nil, fn tile, _acc ->
      if x_overlap(tile.x, x) && y_overlap(tile.y, y) do
        {:halt, tile}
      else
        {:cont, nil}
      end
    end)
  end

  def get_overlaps(x, y, tiles) do
    Enum.reduce(Map.values(tiles), [], fn tile, acc ->
      if x_overlap(tile.x, x) && y_overlap(tile.y, y) do
        [tile | acc]
      else
        acc
      end
    end)
  end

  def fix_overlaps(main_tile, overlapping, all_tiles, all_groups) do
    Enum.reduce(overlapping, %{}, fn tile, acc ->
      case tile.group_id do
        nil ->
          {fx, fy} = fix_pos_hopping(tile, main_tile, all_tiles)
          Map.put(acc, tile.id, %{tile | x: fx, y: fy})

        _ ->
          new_children = fix_pos_hopping_group(tile, main_tile, all_tiles, all_groups)
          Map.merge(acc, new_children)
      end
    end)
  end

  defp x_overlap(one, two) do
    Kernel.abs(one - two) < Common.tile_width()
  end

  defp y_overlap(one, two) do
    Kernel.abs(one - two) < Common.tile_height()
  end

  defp fix_pos_hopping(move_tile, main_tile, all_tiles) do
    {sx, sy} = suggested_pos_given_overlap(move_tile, main_tile)
    overlap = overlaps_any(sx, sy, Map.delete(all_tiles, move_tile.id))

    unless is_nil(overlap) do
      fix_pos_hopping(%{move_tile | x: sx, y: sy}, main_tile, all_tiles)
    else
      {sx, sy}
    end
  end

  def fix_pos_hopping_group(lead_move_tile, main_tile, all_tiles, all_groups) do
    children = Map.get(all_groups, lead_move_tile.group_id).children
    {sx, sy} = suggested_pos_given_overlap(lead_move_tile, main_tile)

    {delta_x, delta_y} = {sx - lead_move_tile.x, sy - lead_move_tile.y}

    exp_children =
      Enum.reduce(Map.take(all_tiles, children), %{}, fn {_idx, tile}, acc ->
        {fx, fy} = {tile.x + delta_x, tile.y + delta_y}
        Map.put(acc, tile.id, %{tile | x: fx, y: fy})
      end)

    any_overlap =
      Enum.reduce_while(exp_children, false, fn {_idx, tile}, _acc ->
        case overlaps_any(tile.x, tile.y, Map.drop(all_tiles, children)) do
          nil ->
            {:cont, false}

          _ ->
            {:halt, true}
        end
      end)

    if any_overlap do
      fix_pos_hopping_group(
        %{lead_move_tile | x: sx, y: sy},
        main_tile,
        Map.merge(all_tiles, exp_children),
        all_groups
      )
    else
      exp_children
    end
  end

  defp suggested_pos_given_overlap(to_move, static) do
    x = coordinate_pos_fix(to_move.x, static.x)
    y = coordinate_pos_fix(to_move.y, static.y)
    {x, y}
  end

  defp coordinate_pos_fix(move, static) do
    if move < static do
      move - @fix_overlap_precision
    else
      move + @fix_overlap_precision
    end
  end
end
