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
    test "can send move and others will receive", t do
      {room_id, peer_id, %{1 => other_ws}} = Room.create_in_game_state(t.client_ws, :rumble, 1)

      WsClient.send_msg(t.client_ws, "rumble:move_tile", %{
        id: 0,
        x: 60,
        y: 60
      })

      WsClient.assert_frame("tile_moved", %{"id" => 0, "x" => 60, "y" => 60}, other_ws)
    end

    test "can move tiles and landing will reflect the change", t do
      {room_id, peer_id, _others} = Room.create_in_game_state(t.client_ws, :rumble, 1)

      WsClient.send_msg(t.client_ws, "rumble:move_tile", %{
        id: 0,
        x: 60,
        y: 60
      })

      other_ws = WsClientFactory.create_client_for(Factory.user_token())

      Room.join_existing(other_ws, room_id)

      WsClient.assert_frame("landing", %{
        "milestone" => %{
          "state" => "game",
          "tiles" => [
            %{
              "id" => 0,
              "x" => 60,
              "y" => 60
            }
            | _others
          ]
        }
      })
    end
  end
end
