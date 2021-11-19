defmodule Ports.Rumble.Bag do
  alias Ports.Rumble.TileData

  defstruct tiles: []

  @type t :: %__MODULE__{
          tiles: [TileData.t()]
        }

  def draw_random(bag) do
    index = Enum.random(Enum.to_list(0..(Enum.count(bag.tiles) - 1)))
    item = Enum.at(bag.tiles, index)
    {item, %{bag | tiles: List.delete_at(bag.tiles, index)}}
  end

  def create_initial() do
    tiles =
      Enum.reduce(1..13, [], fn i, acc ->
        Enum.reduce(1..4, acc, fn c, acc ->
          Enum.reduce(1..2, acc, fn _, acc ->
            [%TileData{value: i, color: c} | acc]
          end)
        end)
      end)

    # Add the jokers
    %__MODULE__{tiles: [%TileData{value: -1, color: 1}, %TileData{value: -1, color: 2} | tiles]}
  end
end
