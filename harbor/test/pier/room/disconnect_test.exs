defmodule PierTest.Room.DisconnectTest do
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

  describe "disconnecting from the room" do
    test "other peer receives leave message", t do
      {room_id, host_id} = Room.create_and_join(t.client_ws, :rumble)

      other_ws = WsClientFactory.create_client_for(Factory.user_token())
      Room.join_existing(other_ws, room_id)

      Process.exit(t.client_ws, :kill)

      WsClient.assert_frame("peer_leave", %{"id" => ^host_id}, other_ws)
    end
  end
end
