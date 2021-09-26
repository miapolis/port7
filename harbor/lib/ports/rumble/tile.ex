defmodule Ports.Rumble.Tile do
  @derive Jason.Encoder

  defstruct id: 0, x: 0, y: 0

  @type t :: %__MODULE__{
          id: integer(),
          x: integer(),
          y: integer()
        }
end