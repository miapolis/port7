defmodule Ports.Rumble.Milestone do
  defimpl Jason.Encoder, for: __MODULE__ do
    def encode(value, opts) do
      to_encode =
        value
        |> Map.from_struct()
        |> Enum.filter(fn {_, value} -> not is_nil(value) end)
        |> Enum.map(fn {key, value} -> {transform_key(key), value} end)
        |> Enum.into(%{})

      Jason.Encode.map(Map.take(to_encode, [:state, :startTime, :serverNow, :currentTurn]), opts)
    end

    defp transform_key(old_key) do
      case old_key do
        :start_time -> :startTime
        :current_turn -> :currentTurn
        x -> x
      end
    end
  end

  defstruct state: nil, start_time: nil, start_timer: nil, current_turn: nil

  @type t :: %__MODULE__{
          state: atom(),
          start_time: number(),
          start_timer: any(),
          current_turn: integer()
        }

  use Fsmx.Struct, fsm: __MODULE__.StateMachine
end

defmodule Ports.Rumble.Milestone.StateMachine do
  use Fsmx.Fsm,
    transitions: %{
      :lobby => :game,
      :game => [:scores, :podium],
      :scores => :game,
      :podium => :lobby
    }

  def before_transition(%{current_turn: nil}, _initial, :game) do
    {:error, "cannot transition to game without setting the current turn"}
  end
end
