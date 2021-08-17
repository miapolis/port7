defmodule Pier.Routes.Room do
  import Plug.Conn

  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get "/:code" do
    %Plug.Conn{params: %{"code" => code}} = conn

    room = Harbor.Room.get_by_code(code)

    cond do
      is_nil(room) ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          400,
          Jason.encode!(%{error: "room does not exist"})
        )

      true ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          200,
          Jason.encode!(%{room: room})
        )
    end
  end

  match _ do
    send_resp(conn, 404, "not found")
  end
end
