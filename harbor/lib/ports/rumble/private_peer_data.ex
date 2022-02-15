defmodule Ports.Rumble.PrivatePeerData do
  alias Ports.Rumble.TileData

  @derive Jason.Encoder

  defstruct hand: []

  @type t :: %__MODULE__{
          hand: [TileData.t()]
        }
end
