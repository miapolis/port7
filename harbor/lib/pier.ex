defmodule Pier do
  import Plug.Conn
  use Plug.Router

  alias Pier.Routes.Room

  plug(:match)
  plug(:dispatch)

  forward("/room", to: Room)

  match _ do
    send_resp(conn, 404, "not found")
  end
end
