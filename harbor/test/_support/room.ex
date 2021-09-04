defmodule PierTest.Helpers.Room do
  alias PierTest.WsClient
  require WsClient

  @spec create_and_join(any(), atom()) :: Stringt.t()
  def create_and_join(ws, game) do
    %{"id" => room_id} =
      WsClient.do_call(ws, "room:create", %{
        "name" => "foo",
        "isPrivate" => false,
        "game" => Atom.to_string(game)
      })

    WsClient.do_call(ws, "room:join", %{"roomId" => room_id})
    room_id
  end
end
