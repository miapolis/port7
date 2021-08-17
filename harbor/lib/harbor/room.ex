defmodule Harbor.Room do
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

    room = %Anchorage.RoomSession.State{
      room_id: id,
      room_creator_id: user_id,
      room_name: room_name,
      room_code: code,
      is_private: is_private,
      game: game
    }

    Anchorage.RoomSession.start_supervised(
      room_id: id,
      room_creator_id: user_id,
      room_name: room_name,
      room_code: code,
      is_private: is_private,
      game: game
    )

    {:ok, %{room: room}}
  end
end
