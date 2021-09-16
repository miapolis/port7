defmodule PortsTests.Rumble.Message.Landing.LandingTest do
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

  describe "validate landing" do
    test "single peer", t do
      Room.create_and_join(t.client_ws, :rumble)

      WsClient.assert_frame(
        "landing",
        %{
          "milestone" => %{"state" => "lobby", "serverNow" => _some_val},
          "peers" => [%{"id" => 0, "nickname" => "TEST USER", "isJoined" => false}]
        }
      )
    end

    test "second peer", t do
      {room_id, _} = Room.create_and_join(t.client_ws, :rumble)
      second_ws = WsClientFactory.create_client_for(Factory.user_token())

      Room.join_existing(second_ws, room_id)

      WsClient.assert_frame(
        "landing",
        %{
          "milestone" => %{"state" => "lobby", "serverNow" => _some_val},
          "peers" => [
            %{"id" => 0, "nickname" => "TEST USER", "isJoined" => false},
            %{"id" => 1, "nickname" => "TEST USER", "isJoined" => false}
          ]
        },
        second_ws
      )
    end

    test "first peer leaves and receives same landing", t do
      {room_id, _} = Room.create_and_join(t.client_ws, :rumble)
      second_ws = WsClientFactory.create_client_for(Factory.user_token())

      Room.join_existing(second_ws, room_id)
      Process.exit(t.client_ws, :kill)

      restarted_ws = WsClientFactory.create_client_for(t.user_id)
      Room.join_existing(restarted_ws, room_id)

      WsClient.assert_frame(
        "landing",
        %{
          "milestone" => %{"state" => "lobby", "serverNow" => _some_val},
          "peers" => [
            %{"id" => 0, "nickname" => "TEST USER", "isJoined" => false},
            %{"id" => 1, "nickname" => "TEST USER", "isJoined" => false}
          ]
        },
        restarted_ws
      )
    end
  end
end
