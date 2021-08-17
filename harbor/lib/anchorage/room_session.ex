defmodule Anchorage.RoomSession do
  use GenServer, restart: :temporary

  defmodule State do
    @type t :: %__MODULE__{
            room_id: String.t(),
            room_creator_id: String.t(),
            room_name: String.t(),
            room_code: String.t(),
            is_private: String.t(),
            users: [String.t()],
            game: atom()
          }

    defstruct room_id: "",
              room_creator_id: "",
              room_name: "",
              room_code: "",
              is_private: false,
              users: [],
              game: :none
  end

  defp via(user_id), do: {:via, Registry, {Anchorage.RoomSessionRegistry, user_id}}

  defp cast(user_id, params), do: GenServer.cast(via(user_id), params)
  defp call(user_id, params), do: GenServer.call(via(user_id), params)

  def start_supervised(initial_values) do
    case DynamicSupervisor.start_child(
           Anchorage.RoomSessionDynamicSupervisor,
           {__MODULE__, initial_values}
         ) do
      {:error, {:already_started, pid}} -> {:ignored, pid}
      error -> error
    end
  end

  def child_spec(init), do: %{super(init) | id: Keyword.get(init, :room_id)}

  def count, do: Registry.count(Anchorage.RoomSessionRegistry)
  def lookup(room_id), do: Registry.lookup(Anchorage.RoomSessionRegistry, room_id)

  def start_link(init) do
    GenServer.start_link(__MODULE__, init, name: via(init[:room_id]))
  end

  def init(init) do
    Anchorage.Chat.start_link_supervised(init)
    {:ok, struct(State, init)}
  end

  def ws_fan(users, msg) do
    Enum.each(users, fn uid ->
      Anchorage.UserSession.send_ws(uid, nil, msg)
    end)
  end
end
