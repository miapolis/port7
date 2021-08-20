defmodule Harbor.Room do
  alias Anchorage.PubSub
  alias Harbor.Peer

  @max_room_size 100

  def create_room(
        user_id,
        room_name,
        is_private,
        game
      ) do
    IO.puts("creating room...")
    id = Ecto.UUID.generate()
    # TODO: store codes to prevent duplication (probably just a genserver)
    code = Habor.Utils.GenCode.room_code()

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
      game: room.game,
    )

    {:ok, %{room: room}}
  end

  def join_room(room_id, user_id) do
    current_room_id = Anchorage.UserSession.get_current_room_id(user_id)

    if current_room_id == room_id do
      room = Anchorage.RoomSession.get_state(room_id)
      peer_id = Map.fetch!(room.peers, user_id)
      %{room: room, peer_id: peer_id}
    else
      case can_join_room(room_id, user_id) do
        {:error, message} ->
          %{error: message}

        {:ok, room} ->
          peer_id = gen_peer_id(room);
          peer = %Peer{id: peer_id}

          Anchorage.RoomSession.join_room(room.room_id, user_id, peer)

          Anchorage.PubSub.subscribe("chat:" <> room_id)

          %{room: room, peer_id: peer_id}
      end
    end
  end

  # TODO: In the future, we will have room blocks and all that
  def can_join_room(room_id, _user_id) do
    room = Anchorage.RoomSession.get_state(room_id)
    peers = room.peers

    cond do
      Enum.count(peers) > @max_room_size ->
        {:error, "room is full"}

      true ->
        {:ok, room}
    end
  end

  # @spec get_by_code(String.t()) :: Anchorage.RoomSession.State.t() | nil
  def get_by_code(code) do
    room_id = Anchorage.RoomCode.get(code)

    if not is_nil(room_id) do
      Anchorage.RoomSession.get_state(room_id)
    else
      nil
    end
  end

  def leave_room(user_id, current_room_id) do
    if current_room_id do
      Anchorage.RoomSession.leave_room(current_room_id, user_id)

      PubSub.unsubscribe("chat:" <> current_room_id)

      {:ok, %{roomId: current_room_id}}
    end
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
end
