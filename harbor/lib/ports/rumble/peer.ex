defmodule Ports.Rumble.Peer do
  alias Ports.Rumble.TileData

  defimpl Jason.Encoder, for: __MODULE__ do
    def encode(value, opts) do
      to_encode =
        value
        |> Map.from_struct()
        |> Enum.map(fn {key, value} -> {transform_key(key), value} end)
        |> Enum.into(%{})

      Jason.Encode.map(Map.take(to_encode, [:id, :nickname, :isJoined]), opts)
    end

    defp transform_key(old_key) do
      case old_key do
        :is_joined -> :isJoined
        x -> x
      end
    end
  end

  defstruct id: 0, user_id: nil, nickname: "", is_disconnected: false, is_joined: false, hand: nil

  @type t :: %__MODULE__{
          id: integer(),
          user_id: String.t(),
          nickname: String.t(),
          is_disconnected: boolean(),
          is_joined: boolean(),
          hand: [TileData.t()]
        }
end
