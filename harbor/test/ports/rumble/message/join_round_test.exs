defmodule PortsTests.Rumble.Message.JoinRound.JoinRoundTest do
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

  describe "the websocket rumble:join_round operation" do
    test "assert reply", t do
      {_room_id, _} = Room.create_and_join(t.client_ws, :rumble)

      WsClient.send_msg(t.client_ws, "rumble:join_round", %{})

      WsClient.assert_frame(
        "peer_joined_round",
        %{"id" => 0, "nickname" => "TEST USER"},
        t.client_ws
      )
    end
  end
end
