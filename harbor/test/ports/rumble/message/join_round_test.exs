defmodule PortsTests.Rumble.Message.JoinRound.JoinRoundTest do
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

  describe "the websocket rumble:join_round operation" do
    test "assert reply", t do

    end
  end
end
