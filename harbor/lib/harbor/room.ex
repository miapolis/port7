defmodule Harbor.Room do
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
      room_creator_id: user_id,
      room_name: room.name,
      room_code: room.code,
      is_private: room.isPrivate,
      game: room.game
    )

    Anchorage.RoomSession.join_room(room.id, user_id, no_fan: true)

    # Subscribe to room chat
    Anchorage.PubSub.subscribe("chat:" <> id)

    {:ok, %{room: room}}
  end

  def join_room(room_id, user_id) do
    current_room_id = Anchorage.UserSession.get_current_room_id(user_id)

    if current_room_id == room_id do
      %{room: Anchorage.RoomSession.get_state(room_id)}
    else
      case can_join_room(room_id, user_id) do
        {:error, message} ->
          %{error: message}

        {:ok, room} ->
          Anchorage.RoomSession.join_room(room.room_id, user_id)

          Anchorage.PubSub.subscribe("chat:" <> room_id)

          %{room: room}
      end
    end
  end

  # TODO: In the future, we will have room blocks and all that
  def can_join_room(room_id, _user_id) do
    room = Anchorage.RoomSession.get_state(room_id)
    users = room.users

    cond do
      length(users) > @max_room_size ->
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
end
