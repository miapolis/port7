defmodule Ports.Rumble.TileData do
  @derive Jason.Encoder

  defstruct value: 0, color: 0

  @type t :: %__MODULE__{
          value: integer(),
          color: integer()
        }

  def joker?(tile_data) do
    tile_data.value === -1
  end
end
