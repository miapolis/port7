defmodule Pier.SockerHandler do
  require Logger

  defstruct ip: nil

  @type state :: %__MODULE__{
          ip: String.t()
        }

  @behaviour :cowboy_websocket

  @impl true
  def init(request, _state) do
    ip = request.headers["x-forwarded-for"]

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

  def exit(pid), do: send(pid, :exit)
  @spec exit_impl(state) :: call_result
  defp exit_impl(state) do
    ws_push([{:close, 4003, "killed by server"}, shutdown: :normal], state)
  end

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

  @spec validate(map, state) :: {:ok, Pier.Message.t()} | {:error, Ecto.Changeset.t()}
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

  def prepare_socket_msg(data), do: {:text, Jason.encode!(data)}

  defp ws_push(frame, state) do
    {List.wrap(frame), state}
  end

  @impl true
  def websocket_info({:EXIT, _, _}, state), do: exit_impl(state)
end
