defmodule PierTest.Room.KickTest do
  use ExUnit.Case, async: true

  alias PierTest.WsClient
  alias PierTest.WsClientFactory
  alias HarborTest.Support.Factory

  require WsClient

  setup do
    user_id = Factory.user_token()
    client_ws = WsClientFactory.create_client_for(user_id)

    {:ok, user_id: user_id, client_ws: client_ws}
  end

  describe "the websocket room:kick operation" do
    test "assert user to kick was kicked", t do
      %{"id" => room_id} =
        WsClient.do_call(t.client_ws, "room:create", %{
          "name" => "foo",
          "isPrivate" => false,
          "game" => "rumble"
        })

        WsClient.do_call(t.client_ws, "room:join", %{"roomId" => room_id})

        other_ws = WsClientFactory.create_client_for(Factory.user_token())

        %{"myPeerId" => toKickId} = WsClient.do_call(other_ws, "room:join", %{"roomId" => room_id})

        WsClient.send_msg(t.client_ws, "room:kick", %{"id" => toKickId})

        WsClient.assert_frame("kicked", %{"type" => "kick"}, other_ws)
    end
  end
end
