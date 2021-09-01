defmodule PierTest.Room.CreateTest do
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

  describe "the websocket room:create operation" do
    test "assert reply", t do
      ref =
        WsClient.send_call(
          t.client_ws,
          "room:create",
          %{
            "name" => "foo",
            "isPrivate" => false,
            "game" => "rumble"
          }
        )

      WsClient.assert_reply("room:create:reply", ref, %{
        "id" => _room_id,
        "name" => "foo",
        "code" => _room_code,
        "isPrivate" => false,
        "game" => "rumble"
      })
    end
  end
end
