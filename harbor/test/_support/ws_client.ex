defmodule PierTest.WsClient do
  use WebSockex

  @api_url Application.compile_env!(:harbor, :api_url)

  def child_spec(info) do
    info
    |> super
    |> Map.put(:id, UUID.uuid4())
  end

  def start_link(_opts) do
    ancestors =
      :"$ancestors"
      |> Process.get()
      |> :erlang.term_to_binary()
      |> Base.encode16()

    @api_url
    |> Path.join("socket")
    |> WebSockex.start_link(__MODULE__, nil,
      extra_headers: [{"user-agent", ancestors}, {"x-forwarded-for", "127.0.0.1"}]
    )
  end

  def send_call(client_ws, op, payload) do
    call_ref = UUID.uuid4()

    WebSockex.cast(
      client_ws,
      {:send, %{"op" => op, "p" => payload, "ref" => call_ref}}
    )

    call_ref
  end

  def do_call(ws, op, payload) do
    ref = send_call(ws, op, payload)
    reply_op = op <> ":reply"

    receive do
      {:text, %{"op" => ^reply_op, "ref" => ^ref, "p" => payload}, ^ws} ->
        payload
    after
      100 ->
        raise "reply to `#{op}` not received"
    end
  end

  def send_msg(client_ws, op, payload) do
    WebSockex.cast(client_ws, {:send, %{"op" => op, "p" => payload}})
  end

  defp send_msg_impl(map, test_pid) do
    {:reply, {:text, Jason.encode!(map)}, test_pid}
  end

  def forward_frames(client_ws), do: WebSockex.cast(client_ws, {:forward_frames, self()})
  defp forward_frames_impl(test_pid, _state), do: {:ok, test_pid}

  defmacro assert_frame(op, payload, from \\ nil) do
    if from do
      quote do
        from = unquote(from)

        ExUnit.Assertions.assert_receive(
          {:text, %{"op" => unquote(op), "d" => unquote(payload)}, ^from}
        )
      end
    else
      quote do
        ExUnit.Assertions.assert_receive(
          {:text, %{"op" => unquote(op), "d" => unquote(payload)}, _}
        )
      end
    end
  end

  defmacro assert_reply(op, ref, payload, from \\ nil) do
    if from do
      quote do
        op = unquote(op)
        from = unquote(from)
        ref = unquote(ref)

        ExUnit.Assertions.assert_receive(
          {:text, %{"op" => ^op, "p" => unquote(payload), "ref" => ^ref}, ^from}
        )
      end
    else
      quote do
        op = unquote(op)
        ref = unquote(ref)

        ExUnit.Assertions.assert_receive(
          {:text, %{"op" => ^op, "p" => unquote(payload), "ref" => ^ref}, _}
        )
      end
    end
  end

  defmacro assert_error(op, ref, error, from \\ nil) do
    if from do
      quote do
        op = unquote(op)
        from = unquote(from)
        ref = unquote(ref)

        ExUnit.Assertions.assert_receive(
          {:text, %{"op" => ^op, "e" => unquote(error), "ref" => ^ref}, ^from}
        )
      end
    else
      quote do
        op = unquote(op)
        ref = unquote(ref)

        ExUnit.Assertions.assert_receive(
          {:text, %{"op" => ^op, "e" => unquote(error), "ref" => ^ref}, _}
        )
      end
    end
  end

  defmacro assert_dies(client_ws, fun, reason, timeout \\ 100) do
    quote bind_quoted: [client_ws: client_ws, fun: fun, reason: reason, timeout: timeout] do
      Process.flag(:trap_exit, true)
      Process.link(client_ws)
      fun.()
      ExUnit.Assertions.assert_receive({:EXIT, ^client_ws, ^reason}, timeout)
    end
  end

  defmacro refute_frame(op, from) do
    quote do
      from = unquote(from)
      ExUnit.Assertions.refute_receive({:text, %{"op" => unquote(op)}, ^from})
    end
  end

  ### - ROUTER - ######################################################################

  @impl true
  def handle_frame({type, data}, test_pid) do
    send(test_pid, {type, Jason.decode!(data), self()})
    {:ok, test_pid}
  end

  @impl true
  def handle_cast({:send, map}, test_pid), do: send_msg_impl(map, test_pid)
  def handle_cast({:forward_frames, test_pid}, state), do: forward_frames_impl(test_pid, state)
end

defmodule PierTest.WsClientFactory do
  alias PierTest.WsClient
  require WsClient

  # import ExUnit.Assertions

  def create_client_for(user_id, _opts \\ []) do
    client_ws = ExUnit.Callbacks.start_supervised!(WsClient)
    WsClient.forward_frames(client_ws)

    WsClient.do_call(client_ws, "auth:request", %{
      "userToken" => user_id,
      "nickname" => "TEST USER"
    })

    [{usersession_pid, _}] = Registry.lookup(Anchorage.UserSessionRegistry, user_id)
    Process.link(usersession_pid)

    client_ws
  end
end
