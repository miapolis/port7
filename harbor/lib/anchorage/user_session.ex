defmodule Anchorage.UserSession do
  use GenServer, restart: :temporary

  require Logger

  @idle_timeout_ms 60000

  defmodule State do
    @derive {Jason.Encoder, only: [:nickname]}

    @type t :: %__MODULE__{
            user_id: String.t(),
            is_disconnected: boolean(),
            nickname: String.t(),
            current_room_id: String.t(),
            peer_id: integer(),
            ip: String.t(),
            pid: pid(),
            idle_timer_ref: any()
          }

    defstruct user_id: nil,
              is_disconnected: false,
              nickname: nil,
              current_room_id: nil,
              peer_id: nil,
              ip: nil,
              pid: nil,
              idle_timer_ref: nil
  end

  defp via(user_id), do: {:via, Registry, {Anchorage.UserSessionRegistry, user_id}}

  defp cast(user_id, params), do: GenServer.cast(via(user_id), params)
  defp call(user_id, params), do: GenServer.call(via(user_id), params)

  @spec start_supervised(nil | maybe_improper_list | map) ::
          :ignore | {:error, any} | {:ignored, any} | {:ok, pid} | {:ok, pid, any}
  def start_supervised(values) do
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
    if not state.is_disconnected && pid do
      Pier.SocketHandler.remote_send(pid, msg)
    end

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

  def set_nickname(user_id, nickname) do
    call(user_id, {:set_nickname, nickname})
  end

  defp set_nickname_impl(nickname, _reply, state) do
    {:reply, :ok, %{state | nickname: nickname}}
  end

  def set_current_room_id(user_id, current_room_id) do
    set_state(user_id, %{current_room_id: current_room_id})
  end

  def init(init) do
    {:ok, struct(State, init)}
  end

  defp handle_disconnect(pid, :normal, state = %{ip: _ip, pid: pid}) do
    if state.current_room_id do
      Harbor.Room.disconnect_from_room(state.current_room_id, state.user_id)

      # We only care about keeping the process alive if others depend on
      # the possibility that the user was disconnected due to a bad internet
      # connection. Otherwise, we can terminate the process immediately
      idle_timeout_ref = make_ref()

      idle_timer_ref =
        Process.send_after(self(), {:idle_timeout, idle_timeout_ref}, @idle_timeout_ms)

      {:noreply, %{state | idle_timer_ref: idle_timer_ref, is_disconnected: true}}
    else
      {:stop, :normal, state}
    end
  end

  defp handle_disconnect(_, reason, state) do
    Logger.debug("Ending for reason " <> reason)
    # Immediate termination
    if state.current_room_id && state.user_id do
      Harbor.Room.remove_user(state.current_room_id, state.user_id)
    end

    {:stop, :normal, state}
  end

  def reconnect(user_id), do: call(user_id, {:reconnect})

  defp reconnect_impl(_reply, state) do
    if state.current_room_id && state.idle_timer_ref do
      Process.cancel_timer(state.idle_timer_ref)
    end

    {:reply, state, %{state | idle_timer_ref: nil, is_disconnected: false}}
  end

  ### - ROUTER - ######################################################################

  def handle_cast({:send_ws, platform, msg}, state), do: send_ws_impl(platform, msg, state)
  def handle_cast({:set_state, info}, state), do: set_state_impl(info, state)

  def handle_call({:set_active_ws, pid}, reply, state), do: set_active_ws(pid, reply, state)

  def handle_call({:set_nickname, nickname}, reply, state),
    do: set_nickname_impl(nickname, reply, state)

  def handle_call({:get, key}, reply, state), do: get_impl(key, reply, state)
  def handle_call({:get_state}, reply, state), do: get_state_impl(reply, state)
  def handle_call({:reconnect}, reply, state), do: reconnect_impl(reply, state)

  def handle_info({:DOWN, _ref, :process, pid, reason}, state),
    do: handle_disconnect(pid, reason, state)

  def handle_info(
        {:idle_timeout, _idle_timeout_ref},
        %{idle_timer_ref: _idle_timer_ref} = state
      ) do
    if state.current_room_id do
      Harbor.Room.remove_user(state.current_room_id, state.user_id)
    end

    # Terminate the process completely
    {:stop, :normal, state}
  end

  def handle_info({:idle_timeout, _ref}, state), do: {:noreply, state}
end
