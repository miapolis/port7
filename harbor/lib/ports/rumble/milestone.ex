defmodule Ports.Rumble.Milestone do
  defimpl Jason.Encoder, for: __MODULE__ do
    def encode(value, opts) do
      to_encode =
        value
        |> Map.from_struct()
        |> Enum.filter(fn {_, value} -> not is_nil(value) end)
        |> Enum.map(fn {key, value} -> {transform_key(key), value} end)
        |> Enum.into(%{})

      Jason.Encode.map(Map.take(to_encode, [:name, :startTime, :serverNow]), opts)
    end

    defp transform_key(old_key) do
      case old_key do
        :start_time -> :startTime
        x -> x
      end
    end
  end

  defstruct name: nil, start_time: nil, start_timer: nil

  @type t :: %__MODULE__{
          name: atom(),
          start_time: number(),
          start_timer: any()
        }
end
