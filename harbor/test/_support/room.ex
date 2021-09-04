defmodule PierTest.Helpers.Room do
  alias PierTest.WsClient
  require WsClient

  @spec create_and_join(any(), atom()) :: {String.t(), integer()}
  def create_and_join(ws, game) do
    %{"id" => room_id} =
      WsClient.do_call(ws, "room:create", %{
        "name" => "foo",
        "isPrivate" => false,
        "game" => Atom.to_string(game)
      })

    %{"myPeerId" => peer_id} = WsClient.do_call(ws, "room:join", %{"roomId" => room_id})

    {room_id, peer_id}
  end

  @spec join_existing(any(), String.t()) :: integer()
  def join_existing(ws, room_id) do
    %{"myPeerId" => peer_id} = WsClient.do_call(ws, "room:join", %{"roomId" => room_id})
    peer_id
  end
end
