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

    test "assert invalid", t do
      ref = WsClient.send_call(t.client_ws, "room:join", %{"roomId" => "foo"})
      WsClient.refute_frame("room:join:reply", ref)
    end

    test "can't join room when full", t do
      %{"id" => room_id} =
        WsClient.do_call(t.client_ws, "room:create", %{
          "name" => "foo",
          "isPrivate" => false,
          "game" => "rumble"
        })

      WsClient.do_call(t.client_ws, "room:join", %{"roomId" => room_id})

      Enum.each(1..Harbor.Room.max_room_size(), fn _ ->
        new_ws = WsClientFactory.create_client_for(Factory.user_token())
        WsClient.do_call(new_ws, "room:join", %{"roomId" => room_id})

        WsClient.assert_frame("landing", %{}, new_ws)
        WsClient.assert_frame("peer_join", %{}, t.client_ws)
      end)

      last_ws = WsClientFactory.create_client_for(Factory.user_token())

      ref = WsClient.send_call(last_ws, "room:join", %{"roomId" => room_id})

      WsClient.assert_reply("room:join:reply", ref, %{
        "error" => "room is full"
      })
    end
  end
end
