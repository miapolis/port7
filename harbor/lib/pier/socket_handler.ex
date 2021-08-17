defmodule Pier.SocketHandler do
  require Logger

  defstruct user: nil, ip: nil

  @type state :: %__MODULE__{
          user: nil | Anchorage.UserSession.State.t(),
          ip: String.t()
        }

  @behaviour :cowboy_websocket

  @impl true
  def init(request, _state) do
    ip = request.headers["X-Forwarded-For"]

    state = %__MODULE__{
      ip: ip
    }

    {:cowboy_websocket, request, state}
  end

  @impl true
  def websocket_init(state) do
    {:ok, state}
  end

  @typep command :: :cow_ws.frame() | {:shutdown, :normal}
  @typep call_result :: {[command], state}

  ### - API - #################################################################

  def exit(pid), do: send(pid, :exit)
  @spec exit_impl(state) :: call_result
  defp exit_impl(state) do
    ws_push([{:close, 4003, "killed by server"}, shutdown: :normal], state)
  end

  def remote_send(socket, message), do: send(socket, {:remote_send, message})

  @spec remote_send_impl(Harbor.json(), state) :: call_result
  defp remote_send_impl(message, state) do
    ws_push(prepare_socket_msg(message), state)
  end

  ### - CHAT MESSAGES - #######################################################

  defp real_chat_impl({"chat:" <> _room_id, message}, %__MODULE__{} = state) do
    message
    |> prepare_socket_msg
    |> ws_push(state)
  end

  def chat_impl(
        {"chat:" <> _room_id, %Pier.Message{payload: %Pier.Message.Chat.Send{from: _from}}} = p1,
        %__MODULE__{} = state
      ) do
    real_chat_impl(p1, state)
  end

  def chat_impl(
        {"chat:" <> _room_id, _} = p1,
        %__MODULE__{} = state
      ) do
    real_chat_impl(p1, state)
  end

  def chat_impl(_, state), do: ws_push(nil, state)

  ### - WEBSOCKET API - #######################################################

  @impl true
  def websocket_handle({:text, "ping"}, state), do: {[text: "pong"], state}
  @impl true
  def websocket_handle({:ping, _}, state), do: {[text: "pong"], state}

  def websocket_handle({:text, command_json}, state) do
    with {:ok, message_map!} <- Jason.decode(command_json),
         {:ok, message = %{errors: nil}} <- validate(message_map!, state) do
      dispatch(message, state)
    end
  end

  import Ecto.Changeset

  def validate(message, state) do
    message
    |> Pier.Message.changeset(state)
    |> apply_action(:validate)
  end

  def dispatch(message, state) do
    case message.operator.execute(message.payload, state) do
      close when elem(close, 0) == :close ->
        ws_push(close, state)

      {:error, err} ->
        message
        |> wrap_error(err)
        |> prepare_socket_msg
        |> ws_push(state)

      {:error, errors, new_state} ->
        message
        |> wrap_error(errors)
        |> prepare_socket_msg
        |> ws_push(new_state)

      {:noreply, new_state} ->
        ws_push(nil, new_state)

      {:reply, payload, new_state} ->
        message
        |> wrap(payload)
        |> prepare_socket_msg
        |> ws_push(new_state)
    end
  end

  def wrap(message, payload = %{}) do
    %{message | operator: message.inbound_operator <> ":reply", payload: payload}
  end

  defp wrap_error(message, error) do
    Map.merge(
      message,
      %{payload: nil, operator: message.inbound_operator, errors: to_map(error)}
    )
  end

  defp to_map(changeset = %Ecto.Changeset{}) do
    Harbor.Utils.Errors.changeset_errors(changeset)
  end

  defp to_map(string) when is_binary(string) do
    %{message: string}
  end

  defp to_map(other) do
    %{message: inspect(other)}
  end

  def prepare_socket_msg(data) do
    data
    |> encode_data
    |> prepare_data
  end

  defp encode_data(data) do
    Jason.encode!(data)
  end

  defp prepare_data(data) do
    {:text, data}
  end

  defp ws_push(frame, state) do
    {List.wrap(frame), state}
  end

  ### - ROUTER - ##############################################################

  @impl true
  def websocket_info({:EXIT, _, _}, state), do: exit_impl(state)
  def websocket_info(:exit, state), do: exit_impl(state)
  def websocket_info({:remote_send, message}, state), do: remote_send_impl(message, state)
  def websocket_info(message = {"chat:" <> _, _}, state), do: chat_impl(message, state)

  def websocket_info(_, state) do
    ws_push(nil, state)
  end
end
