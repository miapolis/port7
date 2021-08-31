alias Quay.BaseGame

defmodule Ports.Rumble.Game do
  use GenServer, restart: :temporary
  require Logger

  alias Quay.Utils
  alias Ports.Rumble.Peer
  alias Ports.Rumble.Milestone

  @behaviour BaseGame

  defmodule State do
    @type t :: %__MODULE__{
            room_id: String.t(),
            peers: %{integer() => Peer.t()},
            milestone: Milestone.t()
          }

    defstruct room_id: nil, peers: %{}, milestone: nil, start_timer: nil
  end

  @start_game_timeout 15000
  @min_players_for_game 2

  defp via(room_id), do: {:via, Registry, {Anchorage.GameRegistry, room_id}}

  defp cast(room_id, params), do: GenServer.cast(via(room_id), params)
  # defp call(room_id, params), do: GenServer.call(via(room_id), params)

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
           name: :lobby,
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

  defp join_round_impl(peer_id, %{milestone: %{name: :lobby}} = state) do
    new_state =
      case Map.fetch(state.peers, peer_id) do
        {:ok, peer} ->
          if not peer.is_joined do
            Anchorage.RoomSession.broadcast_ws(state.room_id, %{
              op: "peer_joined_round",
              d: %{
                id: peer.id,
                nickname: peer.nickname
              }
            })

            peers = Map.replace!(state.peers, peer_id, %{peer | is_joined: true})
            {start_time, timer} = begin_start_timer(state)

            %{
              state
              | peers: peers,
                milestone: %{state.milestone | start_time: start_time, start_timer: timer}
            }
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
    now = Utils.Time.ms_now()
    then = now + @start_game_timeout

    Anchorage.RoomSession.broadcast_ws(state.room_id, %{
      op: "round_starting",
      d: %{
        in: then,
        now: now
      }
    })

    ref = Process.send_after(self(), {:start_game}, @start_game_timeout)
    {then, ref}
  end

  defp cancel_start_timer(state) do
    Anchorage.RoomSession.broadcast_ws(state.room_id, %{
      op: "cancel_start_round",
      d: %{}
    })

    Process.cancel_timer(state.milestone.start_timer)
  end

  def leave_round(room_id, peer_id) do
    cast(room_id, {:leave_round, peer_id})
  end

  defp leave_round_impl(peer_id, %{milestone: %{name: :lobby}} = state) do
    new_state =
      case Map.fetch(state.peers, peer_id) do
        {:ok, peer} ->
          if peer.is_joined do
            Anchorage.RoomSession.broadcast_ws(state.room_id, %{
              op: "peer_left_round",
              d: %{
                id: peer.id
              }
            })

            peers = Map.replace!(state.peers, peer_id, %{peer | is_joined: false})

            peers_left =
              peers
              |> Map.values()
              |> Enum.filter(&(&1.is_joined == true))
              |> Enum.count()

            start_timer =
              if peers_left < @min_players_for_game do
                cancel_start_timer(state)
                nil
              else
                state.start_time
              end

            %{state | peers: peers, start_timer: start_timer}
          else
            state
          end

        :error ->
          state
      end

    {:noreply, new_state}
  end

  defp leave_round_impl(_peer_id, state), do: {:noreply, state}

  defp handle_remove_peer(peer, state) do
    if state.milestone == :lobby do
      Anchorage.RoomSession.broadcast_ws(state.room_id, %{
        op: "game_remove_peer",
        d: %{
          id: peer.id
        }
      })
    end
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
    handle_remove_peer(peer, state)
    {:noreply, %{state | peers: peers}}
  end

  @impl true
  def handle_cast({:peer_join, user_id, peer}, state), do: peer_join_impl(user_id, peer, state)
  def handle_cast({:peer_leave, peer}, state), do: peer_leave_impl(peer, state)
  def handle_cast({:peer_remove, peer}, state), do: peer_remove_impl(peer, state)

  ### - ROUTER - ######################################################################

  def handle_cast({:join_round, peer_id}, state), do: join_round_impl(peer_id, state)
  def handle_cast({:leave_round, peer_id}, state), do: leave_round_impl(peer_id, state)
end
