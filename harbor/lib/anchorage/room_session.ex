defmodule Anchorage.RoomSession do
  use GenServer, restart: :temporary

  require Logger

  alias Harbor.Utils.Time

  @prune_rooms Application.compile_env!(:harbor, :prune_rooms)
  @room_prune_interval_ms 1000 * 60 * 3
  @max_room_age 1 * 60 * 5

  defmodule State do
    defimpl Jason.Encoder, for: State do
      def encode(value, opts) do
        to_encode =
          value
          |> Map.from_struct()
          |> Enum.map(fn {key, value} -> {transform_key(key), value} end)
          |> Enum.into(%{})

        Jason.Encode.map(Map.take(to_encode, [:id, :name, :code, :isPrivate, :game]), opts)
      end

      @spec transform_key(atom()) :: atom()
      defp transform_key(old_key) do
        case old_key do
          :room_id -> :id
          :room_name -> :name
          :room_code -> :code
          :is_private -> :isPrivate
          x -> x
        end
      end
    end

    @type t :: %__MODULE__{
            room_id: String.t(),
            room_name: String.t(),
            room_code: String.t(),
            is_private: String.t(),
            peers: %{String.t() => Harbor.Peer.t()},
            game: atom(),
            inner_game: Quay.BaseGame,
            last_event_timestamp: Habor.U
          }

    defstruct room_id: "",
              room_name: "",
              room_code: "",
              is_private: false,
              peers: %{},
              game: :none,
              inner_game: nil,
              last_event_timestamp: nil
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

  @dialyzer {:no_match, {:init, 1}}
  def init(init) do
    Logger.debug("CREATING ROOM WITH INIT " <> inspect(init))

    Anchorage.Chat.start_link_supervised(init)

    module = Harbor.Room.get_game_module(init[:game])
    module.start_link_supervised(init)

    if @prune_rooms do
      run_prune_interval()
    end

    {:ok,
     struct(State, Keyword.merge(init, inner_game: module, last_event_timestamp: Time.s_now()))}
  end

  def ws_one(peer, msg) do
    Anchorage.UserSession.send_ws(peer, nil, msg)
  end

  def ws_fan(peers, msg) do
    Enum.each(Map.keys(peers), fn uid ->
      Anchorage.UserSession.send_ws(uid, nil, msg)
    end)
  end

  @spec ws_each(%{any() => any()}) :: any()
  def ws_each(data) do
    for {uid, msg} <- data do
      ws_one(uid, msg)
    end
  end

  ### - ROOM PRUNING - ################################################################

  defp run_prune_interval() do
    Process.send_after(self(), {:prune_check}, @room_prune_interval_ms)
  end

  def handle_info({:prune_check}, state) do
    now = Time.s_now()

    if state.last_event_timestamp + @max_room_age < now do
      Logger.debug("Shutting down room process...")

      ws_fan(state.peers, %{
        op: "kicked",
        d: %{
          type: "inactivity",
          reason: ""
        }
      })

      Harbor.Room.destroy_room(state)

      {:stop, :normal, state}
    else
      run_prune_interval()

      {:noreply, state}
    end
  end

  ### - API - #########################################################################

  def get_state(room_id) do
    call(room_id, {:get_state})
  end

  defp get_state_impl(state) do
    {:reply, state, state}
  end

  def join_room(room_id, user_id, peer, opts \\ []) do
    cast(room_id, {:join_room, user_id, peer, opts})
  end

  defp join_room_impl(user_id, peer, opts, state) do
    Anchorage.Chat.add_user(state.room_id, user_id)

    user = Anchorage.UserSession.get_state(user_id)

    Anchorage.UserSession.set_current_room_id(user_id, state.room_id)

    if not is_nil(user) do
      unless opts[:no_fan] do
        ws_fan(:maps.filter(fn uid, _ -> uid != user_id end, state.peers), %{
          op: "peer_join",
          d: %{
            id: peer.id,
            nickname: user.nickname
          }
        })
      end
    end

    state.inner_game.peer_join(state.room_id, user_id, peer)

    {:noreply,
     %{
       state
       | peers: Map.put(state.peers, user_id, peer)
     }}
  end

  def event(room_id), do: cast(room_id, {:event})

  def disconnect_from_room(room_id, user_id), do: cast(room_id, {:disconnect_from_room, user_id})

  defp disconnect_from_room_impl(user_id, state) do
    {:ok, peer} = Map.fetch(state.peers, user_id)
    peers = Map.replace!(state.peers, user_id, %{peer | is_disconnected: true})

    ws_fan(peers, %{
      op: "peer_leave",
      d: %{id: peer.id}
    })

    state.inner_game.peer_leave(state.room_id, peer)

    {:noreply, %{state | peers: peers}}
  end

  def remove_from_room(room_id, user_id, action \\ :default) do
    cast(room_id, {:remove_from_room, user_id, action})
  end

  defp remove_from_room_impl(user_id, action, state) do
    {:ok, peer} = Map.fetch(state.peers, user_id)
    peers = Map.delete(state.peers, user_id)

    Anchorage.Chat.remove_user(state.room_id, user_id)

    ws_fan(peers, %{
      op: "remove_peer",
      d: %{id: peer.id, action: action}
    })

    # The member that is being removed is the leader
    peers =
      if Enum.member?(peer.roles, :leader) && Enum.count(peers) > 0 do
        # TODO: handle priority better so that mods are prioritized to be promoted
        # over just random users
        {uid, new_leader} = Enum.random(peers)
        new_roles = [:leader | new_leader.roles]

        ws_fan(peers, %{
          op: "new_leader",
          d: %{id: new_leader.id, roles: new_roles}
        })

        Map.replace(peers, uid, %{new_leader | roles: new_roles})
      else
        peers
      end

    state.inner_game.peer_remove(state.room_id, peer)

    {:noreply, %{state | peers: peers}}
  end

  def broadcast_ws(room_id, msg, opts \\ nil), do: cast(room_id, {:broadcast_ws, msg, opts})

  defp broadcast_ws_impl(msg, opts, state) do
    cond do
      is_nil(opts) ->
        ws_fan(state.peers, msg)

      not is_nil(opts[:except]) ->
        ws_fan(:maps.filter(fn _, peer -> peer.id != opts[:except] end, state.peers), msg)
    end

    {:noreply, state}
  end

  ### - ROUTER - ######################################################################

  def handle_call({:get_state}, _reply, state), do: get_state_impl(state)

  def handle_cast({:join_room, user_id, peer, opts}, state),
    do: join_room_impl(user_id, peer, opts, state)

  def handle_cast({:disconnect_from_room, user_id}, state),
    do: disconnect_from_room_impl(user_id, state)

  def handle_cast({:remove_from_room, user_id, action}, state),
    do: remove_from_room_impl(user_id, action, state)

  def handle_cast({:broadcast_ws, msg, opts}, state), do: broadcast_ws_impl(msg, opts, state)

  def handle_cast({:event}, state) do
    {:noreply, %{state | last_event_timestamp: Time.s_now()}}
  end
end
