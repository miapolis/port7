defmodule PierTest.Room.KickTest do
  use ExUnit.Case, async: true

  alias PierTest.WsClient
  alias PierTest.WsClientFactory
  alias PierTest.Helpers.Room
  alias HarborTest.Support.Factory

  require WsClient

  setup do
    user_id = Factory.user_token()
    client_ws = WsClientFactory.create_client_for(user_id)

    {:ok, user_id: user_id, client_ws: client_ws}
  end

  describe "the websocket room:kick operation" do
    test "assert user to kick was kicked", t do
      {room_id, _} = Room.create_and_join(t.client_ws, :rumble)

      other_ws = WsClientFactory.create_client_for(Factory.user_token())

      %{"myPeerId" => toKickId} = WsClient.do_call(other_ws, "room:join", %{"roomId" => room_id})

      WsClient.send_msg(t.client_ws, "room:kick", %{"id" => toKickId})

      WsClient.assert_frame("kicked", %{"type" => "kick"}, other_ws)
    end

    test "cannot kick self", t do
      {_room_id, peer_id} = Room.create_and_join(t.client_ws, :rumble)

      WsClient.send_msg(t.client_ws, "room:kick", %{"id" => peer_id})

      WsClient.refute_frame("remove_peer", t.client_ws)
      WsClient.refute_frame("kicked", t.client_ws)
    end

    test "user without permissions cannot kick", t do
      {room_id, peer_id} = Room.create_and_join(t.client_ws, :rumble)

      other_ws = WsClientFactory.create_client_for(Factory.user_token())
      join_peer_id = Room.join_existing(other_ws, room_id)

      ExUnit.Assertions.assert(join_peer_id == 1)

      WsClient.send_msg(other_ws, "room:kick", %{"id" => peer_id})

      WsClient.refute_frame("remove_peer", other_ws)
      WsClient.refute_frame("kicked", t.client_ws)
    end
  end
end
