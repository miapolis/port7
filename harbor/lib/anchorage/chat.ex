defmodule Anchorage.Chat do
  use GenServer, restart: :temporary

  alias Anchorage.PubSub

  require Logger

  defstruct room_id: "",
            room_creator_id: "",
            users: [],
            last_message_map: %{},
            chat_throttle: 1000

  @type state :: %__MODULE__{
          room_id: String.t(),
          room_creator_id: String.t(),
          last_message_map: %{optional(UUID.t()) => DateTime.t()},
          chat_throttle: integer()
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

  def add_user(room_id, user_id), do: cast(room_id, {:add_user, user_id})

  defp add_user_impl(user_id, state) do
    if user_id in state.users do
      {:noreply, state}
    else
      {:noreply, %{state | users: [user_id | state.users]}}
    end
  end

  ### - SEND MESSAGE - ################################################################

  def send_msg(room_id, payload) do
    cast(room_id, {:send_msg, payload})
  end

  defp send_msg_impl(payload = %{from: from}, %__MODULE__{} = state) do
    # Throttle
    with false <- should_throttle?(from, state) do
      dispatch_message(payload, state)

      {:noreply,
       %{
         state
         | last_message_map: Map.put(state.last_message_map, from, DateTime.utc_now())
       }}
    else
      _ -> {:noreply, state}
    end
  end

  defp dispatch_message(payload, state) do
    PubSub.broadcast("chat:" <> state.room_id, %Pier.Message{
      operator: "chat:send",
      payload: payload
    })

    :ok
  end

  @spec should_throttle?(UUID.t(), state) :: boolean
  defp should_throttle?(user_id, %__MODULE__{last_message_map: m, chat_throttle: ct})
       when is_map_key(m, user_id) do
    DateTime.diff(DateTime.utc_now(), m[user_id], :millisecond) <
      ct
  end

  defp should_throttle?(_, _), do: false

  ### - ROUTER - ######################################################################

  def handle_cast({:set_room_creator_id, id}, state), do: set_room_creator_id_impl(id, state)
  def handle_cast({:add_user, user_id}, state), do: add_user_impl(user_id, state)
  def handle_cast({:send_msg, message}, state), do: send_msg_impl(message, state)
end
