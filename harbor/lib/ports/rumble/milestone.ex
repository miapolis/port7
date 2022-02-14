defmodule Ports.Rumble.Milestone do
  alias Ports.Rumble.Tile
  alias Ports.Rumble.Group
  alias Ports.Rumble.Bag

  defimpl Jason.Encoder, for: __MODULE__ do
    def encode(value, opts) do
      to_encode =
        value
        |> Map.from_struct()
        |> Enum.filter(fn {_, value} -> not is_nil(value) end)
        |> Enum.map(fn {key, value} -> {transform_key(key), value} end)
        |> Enum.into(%{})

      Jason.Encode.map(
        Map.take(to_encode, [:state, :startTime, :serverNow, :currentTurn, :tiles, :groups, :me]),
        opts
      )
    end

    defp transform_key(old_key) do
      case old_key do
        :start_time -> :startTime
        :current_turn -> :currentTurn
        x -> x
      end
    end
  end

  defstruct state: nil,
            start_time: nil,
            start_timer: nil,
            current_turn: nil,
            tiles: nil,
            groups: nil,
            overlap_map: nil,
            overlap_group_map: nil,
            bag: nil

  @type t :: %__MODULE__{
          state: binary(),
          start_time: number(),
          start_timer: any(),
          current_turn: integer(),
          tiles: %{integer => Tile.t()},
          groups: %{integer => Group.t()},
          overlap_map: %{integer => {number(), number()}},
          overlap_group_map: %{},
          bag: Bag.t()
        }

  def tidy(milestone) do
    case milestone.state do
      "lobby" ->
        milestone

      "game" ->
        %{milestone | tiles: Map.values(milestone.tiles), groups: Map.values(milestone.groups)}
    end
  end

  use Fsmx.Struct, fsm: __MODULE__.StateMachine
end

defmodule Ports.Rumble.Milestone.StateMachine do
  require Logger
  alias Ports.Rumble.Bag

  use Fsmx.Fsm,
    transitions: %{
      "lobby" => "game",
      "game" => ["lobby", "scores", "podium"],
      "scores" => "game",
      "podium" => "lobby"
    }

  def before_transition(%{current_turn: nil}, _initial, "game") do
    {:error, "cannot transition to game without setting the current turn"}
  end

  def before_transition(struct, "lobby", "game") do
    {:ok,
     %{
       struct
       | start_time: nil,
         start_timer: nil,
         tiles: %{},
         groups: %{},
         overlap_map: %{},
         overlap_group_map: %{},
         bag: Bag.create_initial()
     }}
  end

  def before_transition(struct, "game", "lobby") do
    {:ok, %{struct | current_turn: nil}}
  end
end
