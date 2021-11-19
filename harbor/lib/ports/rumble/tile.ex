defmodule Ports.Rumble.Tile do
  alias Ports.Rumble.TileData

  defimpl Jason.Encoder, for: __MODULE__ do
    def encode(value, opts) do
      to_encode =
        value
        |> Map.from_struct()
        |> Enum.map(fn {key, value} -> {transform_key(key), value} end)
        |> Enum.into(%{})

      Jason.Encode.map(
        Map.take(to_encode, [:id, :x, :y, :groupId, :data]),
        opts
      )
    end

    defp transform_key(old_key) do
      case old_key do
        :group_id -> :groupId
        x -> x
      end
    end
  end

  defstruct id: 0, x: 0, y: 0, group_id: 0, data: nil

  @type t :: %__MODULE__{
          id: integer(),
          x: integer(),
          y: integer(),
          group_id: integer(),
          data: TileData.t()
        }
end
