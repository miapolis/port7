defmodule Ports.Rumble.Util.TestBoard do
  alias Ports.Rumble.Tile
  alias Ports.Rumble.Bag

  def initial_tiles(bag) do
    Enum.reduce(0..19, {%{}, bag}, fn i, {data, bag} ->
      {tile, bag} = Bag.draw_random(bag)

      {Map.put(data, i, %Tile{
         id: i,
         x: rem(i, 10) * 110,
         y: if(i < 10, do: 0, else: 140),
         group_id: nil,
         data: tile
       }), bag}
    end)
  end
end
