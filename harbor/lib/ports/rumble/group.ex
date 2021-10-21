defmodule Ports.Rumble.Group do
  @type group_type :: :run | :set

  defimpl Jason.Encoder, for: __MODULE__ do
    def encode(value, opts) do
      to_encode =
        value
        |> Map.from_struct()
        |> Enum.map(fn {key, value} -> {transform_key(key), value} end)
        |> Enum.into(%{})

      Jason.Encode.map(
        Map.take(to_encode, [:id, :children, :groupType]),
        opts
      )
    end

    defp transform_key(old_key) do
      case old_key do
        :group_type -> :groupType
        x -> x
      end
    end
  end

  defstruct id: 0, children: %{}, group_type: nil

  @type t :: %__MODULE__{
          id: integer(),
          children: [integer()],
          group_type: group_type()
        }
end
