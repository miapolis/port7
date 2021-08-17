defmodule Anchorage.Chat do
  use GenServer, restart: :temporary

  require Logger

  defstruct room_id: "",
            room_creator_id: "",
            users: [],
            chat_throttle: 1000

  @type state :: %__MODULE__{
          room_id: String.t(),
          room_creator_id: String.t(),
          chat_throttle: number()
        }

  defp via(user_id), do: {:via, Registry, {Anchorage.RoomChatRegistry, user_id}}

  defp cast(user_id, params), do: GenServer.cast(via(user_id), params)
  defp call(user_id, params), do: GenServer.call(via(user_id), params)

  def start_link_supervised(initial_values) do
    case DynamicSupervisor.start_child(
           Anchorage.RoomChatDynamicSupervisor,
           {__MODULE__, initial_values}
         ) do
      {:ok, pid} ->
        Process.link(pid)
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        Logger.warn(
          "unexpectedly tried to restart already started Room chat #{initial_values[:room_id]}"
        )

        Process.link(pid)
        {:ignored, pid}

      error ->
        error
    end
  end

  def child_spec(init), do: %{super(init) | id: Keyword.get(init, :room_id)}

  def count, do: Registry.count(Anchorage.RoomChatRegistry)

  def start_link(init) do
    GenServer.start_link(__MODULE__, init, name: via(init[:room_id]))
  end

  def init(init) do
    {:ok, struct(__MODULE__, init)}
  end

  def kill(room_id) do
    Anchorage.RoomChatRegistry
    |> Registry.lookup(room_id)
    |> Enum.each(fn {room_pid, _} ->
      Process.exit(room_pid, :kill)
    end)
  end

  def ws_fan(users, msg) do
    Enum.each(users, fn uid ->
      Anchorage.UserSession.send_ws(uid, nil, msg)
    end)
  end

  ### - API - #########################################################################

  def set_room_creator_id(room_id, id) do
    cast(room_id, {:set_room_creator_id, id})
  end

  defp set_room_creator_id_impl(id, %__MODULE__{} = state) do
    {:noreply, %{state | room_creator_id: id}}
  end

  ### - ROUTER - ######################################################################

  def handle_cast({:set_room_creator_id, id}, state), do: set_room_creator_id_impl(id, state)
end
