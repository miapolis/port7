alias Quay.BaseGame

defmodule Ports.Rumble.Game do
  use GenServer, restart: :temporary
  require Logger

  alias Harbor.Utils
  alias Ports.Rumble.Peer
  alias Ports.Rumble.Milestone

  @behaviour BaseGame

  defmodule State do
    @type t :: %__MODULE__{
            room_id: String.t(),
            peers: %{integer() => Peer.t()},
            milestone: Milestone.t()
          }

    defstruct room_id: nil, peers: %{}, milestone: nil
  end

  @min_players_for_game 2
  defp start_game_timeout() do
    elem(Enum.at(:ets.lookup(:config_store, :rumble_default_start), 0), 1) * 1000
  end

  defp via(room_id), do: {:via, Registry, {Anchorage.GameRegistry, room_id}}

  defp cast(room_id, params), do: GenServer.cast(via(room_id), params)
  # defp call(room_id, params), do: GenServer.call(via(room_id), params)

  @impl true
  def start_link_supervised(initial_values) do
    case DynamicSupervisor.start_child(
           Anchorage.GameDynamicSupervisor,
           {__MODULE__, initial_values}
         ) do
      {:ok, pid} ->
        Process.link(pid)
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        Logger.warn("Attempted to restart already started game #{initial_values[:room_id]}")

        Process.link(pid)
        {:ignored, pid}

      error ->
        error
    end
  end

  def child_spec(init), do: %{super(init) | id: Keyword.get(init, :room_id)}

  def start_link(init) do
    GenServer.start_link(__MODULE__, init, name: via(init[:room_id]))
  end

  @impl true
  def init(init) do
    {:ok,
     struct(
       State,
       Keyword.merge(init,
         milestone: %Milestone{
           state: "lobby",
           start_time: nil,
           start_timer: nil
         }
       )
     )}
  end

  ### - API - #########################################################################

  def join_round(room_id, peer_id) do
    cast(room_id, {:join_round, peer_id})
  end

  defp join_round_impl(peer_id, %{milestone: %{state: "lobby"}} = state) do
    new_state =
      case Map.fetch(state.peers, peer_id) do
        {:ok, peer} ->
          if not peer.is_joined do
            Anchorage.RoomSession.event(state.room_id)

            Anchorage.RoomSession.broadcast_ws(state.room_id, %{
              op: "peer_joined_round",
              d: %{
                id: peer.id,
                nickname: peer.nickname
              }
            })

            peers = Map.replace!(state.peers, peer_id, %{peer | is_joined: true})

            # Only start if there are enough joined peers and there isn't already a timer
            if count_joined_peers(peers) >= @min_players_for_game and
                 is_nil(state.milestone.start_timer) do
              {start_time, timer} = begin_start_timer(state)

              %{
                state
                | peers: peers,
                  milestone: %{state.milestone | start_time: start_time, start_timer: timer}
              }
            else
              %{state | peers: peers}
            end
          else
            state
          end

        :error ->
          state
      end

    {:noreply, new_state}
  end

  defp join_round_impl(_peer_id, state), do: {:noreply, state}

  defp begin_start_timer(state) do
    timeout = start_game_timeout()
    now = Utils.Time.ms_now()
    then = now + timeout

    Anchorage.RoomSession.broadcast_ws(state.room_id, %{
      op: "round_starting",
      d: %{
        in: then,
        now: now
      }
    })

    ref = Process.send_after(self(), {:start_game}, timeout)
    {then, ref}
  end

  defp maybe_cancel_start_timer(state, peers) do
    peers_left = count_joined_peers(peers)

    if peers_left < @min_players_for_game and not is_nil(state.milestone.start_timer) do
      cancel_start_timer(state)
      {nil, nil}
    else
      {state.milestone.start_timer, state.milestone.start_time}
    end
  end

  defp cancel_start_timer(state) do
    Anchorage.RoomSession.broadcast_ws(state.room_id, %{
      op: "cancel_start_round",
      d: %{}
    })

    Process.cancel_timer(state.milestone.start_timer)
  end

  defp broadcast_milestone(room_id, milestone) do
    Anchorage.RoomSession.broadcast_ws(room_id, %{
      op: "set_milestone",
      d: milestone
    })
  end

  def start_game(state) do
    milestone = %{state.milestone | current_turn: next_turn(state)}

    case Fsmx.transition(milestone, "game") do
      {:ok, milestone} ->
        broadcast_milestone(state.room_id, milestone)

        %{state | milestone: milestone}

      _ ->
        state
    end
  end

  def return_to_lobby(state) do
    case Fsmx.transition(state.milestone, "lobby") do
      {:ok, milestone} ->
        broadcast_milestone(state.room_id, milestone)
        peers = for {id, peer} <- state.peers, into: %{}, do: {id, %{peer | is_joined: false}}

        %{state | milestone: milestone, peers: peers}

      _ ->
        state
    end
  end

  def leave_round(room_id, peer_id) do
    cast(room_id, {:leave_round, peer_id})
  end

  defp leave_round_impl(peer_id, %{milestone: %{state: "lobby"}} = state) do
    new_state =
      case Map.fetch(state.peers, peer_id) do
        {:ok, peer} ->
          if peer.is_joined do
            Anchorage.RoomSession.event(state.room_id)

            Anchorage.RoomSession.broadcast_ws(state.room_id, %{
              op: "peer_left_round",
              d: %{
                id: peer.id
              }
            })

            peers = Map.replace!(state.peers, peer_id, %{peer | is_joined: false})
            {start_timer, start_time} = maybe_cancel_start_timer(state, peers)

            %{
              state
              | peers: peers,
                milestone: %{state.milestone | start_timer: start_timer, start_time: start_time}
            }
          else
            state
          end

        :error ->
          state
      end

    {:noreply, new_state}
  end

  defp leave_round_impl(_peer_id, state), do: {:noreply, state}

  defp handle_remove_peer(peer, state, remaining_peers) do
    Anchorage.RoomSession.broadcast_ws(state.room_id, %{
      op: "game_remove_peer",
      d: %{
        id: peer.id
      }
    })

    case state.milestone.state do
      "lobby" ->
        {start_timer, start_time} = maybe_cancel_start_timer(state, remaining_peers)

        %{
          state
          | peers: remaining_peers,
            milestone: %{state.milestone | start_timer: start_timer, start_time: start_time}
        }

      "game" ->
        if count_joined_peers(remaining_peers) < @min_players_for_game do
          new_state = return_to_lobby(state)

          filtered_peers =
            :maps.filter(fn id, _ -> Map.has_key?(remaining_peers, id) end, new_state.peers)

          %{
            state
            | milestone: new_state.milestone,
              peers: filtered_peers
          }
        else
          %{state | peers: remaining_peers}
        end
    end
  end

  def next_turn(%{milestone: %{current_turn: nil}} = state) do
    peers = sorted_joined_peers(state.peers)
    Enum.fetch!(peers, 0).id
  end

  def next_turn(state) do
    current = Map.fetch!(state.peers, state.milestone.current_turn)
    peers = sorted_joined_peers(state.peers)
    index = Enum.find_index(peers, fn elem -> elem.id == current.id end)

    next =
      unless index + 1 >= Enum.count(peers) do
        index + 1
      else
        0
      end

    Enum.fetch!(peers, next).id
  end

  defp joined_peers(peers) do
    peers
    |> Map.values()
    |> Enum.filter(&(&1.is_joined == true))
  end

  defp sorted_joined_peers(peers) do
    peers
    |> joined_peers()
    |> Enum.sort(&(&1.id <= &2.id))
  end

  defp count_joined_peers(peers) do
    peers
    |> joined_peers()
    |> Enum.count()
  end

  ### - BEHAVIOUR - ###################################################################

  @impl true
  def peer_join(room_id, user_id, peer) do
    cast(room_id, {:peer_join, user_id, peer})
  end

  defp peer_join_impl(user_id, peer, state) do
    case Map.fetch(state.peers, peer.id) do
      {:ok, fetched} ->
        if fetched.is_disconnected do
          peers = Map.replace!(state.peers, peer.id, %{fetched | is_disconnected: false})

          send_landing(user_id, peers, state)

          {:noreply, %{state | peers: peers}}
        else
          {:noreply, state}
        end

      :error ->
        new_peer = %Peer{
          id: peer.id,
          nickname: peer.nickname,
          is_disconnected: peer.is_disconnected,
          is_joined: false
        }

        peers = Map.put(state.peers, peer.id, new_peer)

        send_landing(user_id, peers, state)

        {:noreply, %{state | peers: peers}}
    end
  end

  defp send_landing(user_id, peers, state) do
    Anchorage.UserSession.send_ws(user_id, nil, %{
      op: "landing",
      d: %{
        peers: Map.values(peers),
        milestone: Map.merge(state.milestone, %{serverNow: Utils.Time.ms_now()})
      }
    })
  end

  @impl true
  def peer_leave(room_id, peer) do
    cast(room_id, {:peer_leave, peer})
  end

  defp peer_leave_impl(peer, state) do
    peer = Map.fetch!(state.peers, peer.id)

    updated = %{peer | is_disconnected: true}
    new_peers = Map.replace!(state.peers, peer.id, updated)
    {:noreply, %{state | peers: new_peers}}
  end

  @impl true
  def peer_remove(room_id, peer) do
    cast(room_id, {:peer_remove, peer})
  end

  defp peer_remove_impl(peer, state) do
    peers = Map.delete(state.peers, peer.id)
    new_state = handle_remove_peer(peer, state, peers)
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:peer_join, user_id, peer}, state), do: peer_join_impl(user_id, peer, state)
  def handle_cast({:peer_leave, peer}, state), do: peer_leave_impl(peer, state)
  def handle_cast({:peer_remove, peer}, state), do: peer_remove_impl(peer, state)

  ### - ROUTER - ######################################################################

  def handle_cast({:join_round, peer_id}, state), do: join_round_impl(peer_id, state)
  def handle_cast({:leave_round, peer_id}, state), do: leave_round_impl(peer_id, state)

  @impl true
  def handle_info(
        {:start_game},
        %{milestone: %{state: "lobby", start_timer: start_timer}} = state
      ) do
    if not is_nil(start_timer) do
      new_state = start_game(state)
      {:noreply, %{state | milestone: new_state.milestone, peers: new_state.peers}}
    else
      {:noreply, state}
    end
  end

  def handle_info({:start_game}, state), do: {:noreply, state}
end
