defmodule Ports.Rumble.Tile do
  defimpl Jason.Encoder, for: __MODULE__ do
    def encode(value, opts) do
      to_encode =
        value
        |> Map.from_struct()
        |> Enum.map(fn {key, value} -> {transform_key(key), value} end)
        |> Enum.into(%{})

      Jason.Encode.map(
        Map.take(to_encode, [:id, :x, :y, :groupId, :groupIndex]),
        opts
      )
    end

    defp transform_key(old_key) do
      case old_key do
        :group_id -> :groupId
        :group_index -> :groupIndex
        x -> x
      end
    end
  end

  defstruct id: 0, x: 0, y: 0, group_id: 0, group_index: 0

  @type t :: %__MODULE__{
          id: integer(),
          x: integer(),
          y: integer(),
          group_id: integer(),
          group_index: integer()
        }
end
