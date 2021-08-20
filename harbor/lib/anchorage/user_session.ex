defmodule Anchorage.UserSession do
  use GenServer, restart: :temporary

  defmodule State do
    @derive {Jason.Encoder, only: [:nickname]}

    @type t :: %__MODULE__{
            user_id: String.t(),
            nickname: String.t(),
            current_room_id: String.t(),
            ip: String.t(),
            pid: pid()
          }

    defstruct user_id: nil,
              nickname: nil,
              current_room_id: nil,
              ip: nil,
              pid: nil
  end

  defp via(user_id), do: {:via, Registry, {Anchorage.UserSessionRegistry, user_id}}

  defp cast(user_id, params), do: GenServer.cast(via(user_id), params)
  defp call(user_id, params), do: GenServer.call(via(user_id), params)

  def start_supervised(values) do
    IO.puts("creating new user #{values[:nickname]} (#{count()})")

    case DynamicSupervisor.start_child(
           Anchorage.UserSessionDynamicSupervisor,
           {__MODULE__, values}
         ) do
      {:error, {:already_started, pid}} -> {:ignored, pid}
      error -> error
    end
  end

  def child_spec(init), do: %{super(init) | id: Keyword.get(init, :user_id)}

  def count, do: Registry.count(Anchorage.UserSessionRegistry)

  def lookup(user_id), do: Registry.lookup(Anchorage.UserSessionRegistry, user_id)

  def start_link(init) do
    GenServer.start_link(__MODULE__, init, name: via(init[:user_id]))
  end

  ### - API - #########################################################################

  def set_state(user_id, info), do: cast(user_id, {:set_state, info})

  defp set_state_impl(info, state) do
    {:noreply, Map.merge(state, info)}
  end

  def get_state(user_id), do: call(user_id, {:get_state})

  defp get_state_impl(_reply, state) do
    {:reply, state, state}
  end

  def get(user_id, key), do: call(user_id, {:get, key})

  defp get_impl(key, _reply, state) do
    {:reply, Map.get(state, key), state}
  end

  def get_current_room_id(user_id) do
    get(user_id, :current_room_id)
  end

  def send_ws(user_id, platform, msg), do: cast(user_id, {:send_ws, platform, msg})

  defp send_ws_impl(_platform, msg, state = %{pid: pid}) do
    # TODO: refactor this to not use ws-datastructures
    if pid, do: Pier.SocketHandler.remote_send(pid, msg)
    {:noreply, state}
  end

  def set_active_ws(user_id, pid), do: call(user_id, {:set_active_ws, pid})

  defp set_active_ws(pid, _reply, state) do
    if state.pid do
      Process.exit(state.pid, :normal)
    end

    Process.monitor(pid)
    {:reply, :ok, %{state | pid: pid}}
  end

  def set_current_room_id(user_id, current_room_id) do
    set_state(user_id, %{current_room_id: current_room_id})
  end

  def init(init) do
    {:ok, struct(State, init)}
  end

  defp handle_disconnect(pid, state = %{ip: ip, pid: pid}) do
    IO.puts("User #{ip} disconnected")

    if state.current_room_id do
      Harbor.Room.leave_room(state.user_id, state.current_room_id)
    end

    {:stop, :normal, state}
  end

  defp handle_disconnect(_, state), do: {:noreply, state}

  ### - ROUTER - ######################################################################

  def handle_cast({:send_ws, platform, msg}, state), do: send_ws_impl(platform, msg, state)
  def handle_cast({:set_state, info}, state), do: set_state_impl(info, state)

  def handle_call({:set_active_ws, pid}, reply, state), do: set_active_ws(pid, reply, state)
  def handle_call({:get, key}, reply, state), do: get_impl(key, reply, state)
  def handle_call({:get_state}, reply, state), do: get_state_impl(reply, state)

  def handle_info({:DOWN, _ref, :process, pid, _reason}, state), do: handle_disconnect(pid, state)
end
