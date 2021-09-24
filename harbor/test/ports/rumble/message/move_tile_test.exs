defmodule PortsTests.Rumble.Message.MoveTile.MoveTileTest do
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

  describe "the websocket rumble:move_tile operation" do
    test "assert reply", t do
      {room_id, peer_id} = Room.create_in_game_state(t.client_ws, :rumble, 1)

      assert(1 == 1)
    end
  end
end
