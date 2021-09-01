defmodule PierTest.Room.JoinTest do
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

  describe "the websocket room:join operation" do
    test "assert reply", t do
      %{"id" => room_id} =
        WsClient.do_call(t.client_ws, "room:create", %{
          "name" => "foo",
          "isPrivate" => false,
          "game" => "rumble"
        })

      ref = WsClient.send_call(t.client_ws, "room:join", %{"roomId" => room_id})

      WsClient.assert_reply("room:join:reply", ref, %{
        "name" => "foo",
        "isPrivate" => false,
        "myPeerId" => 0,
        "myRoles" => ["leader"],
        "peers" => []
      })
    end
  end
end
