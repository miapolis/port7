defmodule PierTest.Helpers.Room do
  alias PierTest.WsClient
  alias Anchorage.RoomSession
  alias PierTest.WsClientFactory
  require WsClient

  @spec create_and_join(any(), atom()) :: {String.t(), integer()}
  def create_and_join(ws, game) do
    %{"id" => room_id} =
      WsClient.do_call(ws, "room:create", %{
        "name" => "foo",
        "isPrivate" => false,
        "game" => Atom.to_string(game)
      })

    %{"myPeerId" => peer_id} = WsClient.do_call(ws, "room:join", %{"roomId" => room_id})

    {room_id, peer_id}
  end

  @spec create_in_game_state(any, any, integer()) :: {binary(), integer()}
  def create_in_game_state(ws, game, other_ws_count) do
    %{"id" => room_id} =
      WsClient.do_call(ws, "room:create", %{
        "name" => "foo",
        "isPrivate" => false,
        "game" => Atom.to_string(game)
      })

    %{"myPeerId" => peer_id} = WsClient.do_call(ws, "room:join", %{"roomId" => room_id})

    Enum.each(1..other_ws_count, fn _ ->
      # TODO: Fix
      other_ws = WsClientFactory.create_client_for("0000000000000000")
      WsClient.do_call(other_ws, "room:join", %{"roomId" => room_id})
    end)

    # TODO: Make behaviour specify this
    room = RoomSession.get_state(room_id)
    state = room.inner_game.get_state(room_id)

    state = room.inner_game.join_all_peers(state)
    state = room.inner_game.start_game(state)

    room.inner_game.set_state(room_id, state)

    {room_id, peer_id}
  end

  @spec join_existing(any(), String.t()) :: integer()
  def join_existing(ws, room_id) do
    %{"myPeerId" => peer_id} = WsClient.do_call(ws, "room:join", %{"roomId" => room_id})
    peer_id
  end
end
