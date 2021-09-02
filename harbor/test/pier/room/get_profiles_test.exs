defmodule PierTest.Room.GetProfilesTest do
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

  describe "the websocket room:get_profiles operation" do
    test "assert reply", t do
      %{"id" => room_id} =
        WsClient.do_call(t.client_ws, "room:create", %{
          "name" => "foo",
          "isPrivate" => false,
          "game" => "rumble"
        })

      WsClient.do_call(t.client_ws, "room:join", %{"roomId" => room_id})

      other_ws = WsClientFactory.create_client_for(Factory.user_token())

      WsClient.do_call(other_ws, "room:join", %{"roomId" => room_id})

      ref = WsClient.send_call(t.client_ws, "room:get_profiles", %{})

      WsClient.assert_reply("room:get_profiles:reply", ref, %{
        "profiles" => [
          %{
            "id" => 1,
            "nickname" => "TEST USER",
            "authMethod" => "port7",
            "authUsername" => "",
            "roles" => []
          },
          %{
            "id" => 0,
            "nickname" => "TEST USER",
            "authMethod" => "port7",
            "authUsername" => "",
            "roles" => ["leader"]
          }
        ]
      })
    end
  end
end
