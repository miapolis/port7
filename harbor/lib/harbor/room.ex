defmodule Harbor.Room do
  alias Anchorage.PubSub
  alias Harbor.Peer

  @max_room_size 100
  def max_room_size, do: @max_room_size

  def create_room(
        room_name,
        is_private,
        game
      ) do
    id = Ecto.UUID.generate()
    code = gen_unique_code()

    room = %Jetty.Room{
      id: id,
      name: room_name,
      code: code,
      isPrivate: is_private,
      game: game
    }

    Anchorage.RoomCode.link_code(code, id)

    Anchorage.RoomSession.start_supervised(
      room_id: room.id,
      room_name: room.name,
      room_code: room.code,
      is_private: room.isPrivate,
      peers: %{},
      game: room.game
    )

    {:ok, %{room: room}}
  end

  @spec join_room(String.t(), String.t()) ::
          %{room: Anchorage.RoomSession.State.t(), peer: Peer.t()} | %{error: atom()}
  def join_room(room_id, user_id) do
    user_state = Anchorage.UserSession.get_state(user_id)
    current_room_id = user_state.current_room_id
    is_disconnected = user_state.is_disconnected

    if current_room_id == room_id do
      if is_disconnected do
        room = Anchorage.RoomSession.get_state(room_id)
        peer = Map.fetch!(room.peers, user_id)
        # If they reconnected, now they are no longer disconnected
        new_peer = %Peer{
          id: peer.id,
          is_disconnected: false,
          nickname: peer.nickname,
          roles: peer.roles
        }

        Anchorage.UserSession.reconnect(user_id)
        Anchorage.RoomSession.join_room(room.room_id, user_id, new_peer)

        Anchorage.PubSub.subscribe("chat:" <> room_id)

        Map.replace!(room.peers, user_id, new_peer)
        %{room: room, peer: new_peer}
      else
        %{error: :already_connected}
      end
    else
      case can_join_room(room_id, user_id) do
        {:error, message} ->
          %{error: message}

        {:ok, room} ->
          peer_id = gen_peer_id(room)

          roles =
            if Enum.count(room.peers) == 0 do
              [:leader]
            else
              []
            end

          peer = %Peer{
            id: peer_id,
            is_disconnected: false,
            nickname: Anchorage.UserSession.get(user_id, :nickname),
            roles: roles
          }

          Anchorage.RoomSession.join_room(room.room_id, user_id, peer)

          Anchorage.PubSub.subscribe("chat:" <> room_id)

          %{room: room, peer: peer}
      end
    end
  end

  def gen_unique_code() do
    code = Habor.Utils.GenCode.room_code()

    if not is_nil(Anchorage.RoomCode.get(code)) do
      gen_unique_code()
    else
      code
    end
  end

  # TODO: In the future, we will have room blocks and all that
  def can_join_room(room_id, _user_id) do
    room = Anchorage.RoomSession.get_state(room_id)
    peers = room.peers

    cond do
      Enum.count(peers) > @max_room_size ->
        {:error, :full}

      true ->
        {:ok, room}
    end
  end

  def get_by_code(code) do
    room_id = Anchorage.RoomCode.get(code)

    if not is_nil(room_id) do
      Anchorage.RoomSession.get_state(room_id)
    else
      nil
    end
  end

  def get_profiles(room_id) do
    Anchorage.RoomSession.get_state(room_id).peers
  end

  # NOTE: Not to be confused with voluntarily leaving the room,
  # here, the user may have been disconnected due to a bad internet
  # connection and therefore we need to wait a minute before we completely
  # kick them from the room
  def disconnect_from_room(current_room_id, user_id) do
    if current_room_id do
      Anchorage.RoomSession.disconnect_from_room(current_room_id, user_id)

      PubSub.unsubscribe("chat:" <> current_room_id)

      {:ok, %{roomId: current_room_id}}
    end
  end

  def kick_user(current_room_id, kicker_user_id, peer_id, reason \\ "") do
    peers = Anchorage.RoomSession.get_state(current_room_id).peers
    user_id = peer_id_to_user_id(peer_id, peers)

    # TODO: fix this nested if/else hell
    if not is_nil(user_id) do
      kicker = Map.fetch!(peers, kicker_user_id)

      if kicker.id != peer_id do
        if Harbor.Permissions.can_manage_members?(kicker.roles) do
          case Anchorage.UserSession.lookup(user_id) do
            [{_, _}] ->
              ws_pid = Anchorage.UserSession.get(user_id, :pid)

              Pier.SocketHandler.unsub(ws_pid, "chat:" <> current_room_id)

              Pier.SocketHandler.remote_send(ws_pid, %{
                op: "kicked",
                d: %{type: "kick", reason: reason}
              })

              Anchorage.UserSession.set_state(user_id, %{current_room_id: nil})
              Pier.SocketHandler.clear_current_room(ws_pid)
          end

          remove_user(current_room_id, user_id, :kick)
          :ok
        else
          {:error, "cannot kick self"}
        end
      else
        {:error, "missing permissions"}
      end
    else
      {:error, "peer does not exist"}
    end
  end

  def remove_user(current_room_id, user_id, action \\ :default) do
    Anchorage.RoomSession.remove_from_room(current_room_id, user_id, action)
  end

  def gen_peer_id(room_state) do
    peer_count = Enum.count(room_state.peers)
    existing_ids = Enum.map(Map.values(room_state.peers), & &1.id)

    Enum.reduce_while(0..(peer_count + 1), 0, fn x, acc ->
      if !Enum.member?(existing_ids, x) do
        {:halt, x}
      else
        {:cont, acc}
      end
    end)
  end

  @spec peer_id_to_user_id(integer(), any()) :: String.t() | nil
  def peer_id_to_user_id(peer_id, peers) do
    Enum.reduce_while(peers, nil, fn {uid, peer}, _acc ->
      if peer.id == peer_id do
        {:halt, uid}
      else
        {:cont, nil}
      end
    end)
  end
end
