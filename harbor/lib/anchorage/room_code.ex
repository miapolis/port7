defmodule Anchorage.RoomCode do
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def get(code) do
    GenServer.call(__MODULE__, {:get, code})
  end

  defp get_impl(code, state) do
    {:reply, Map.get(state, code), state}
  end

  def link_code(code, room_id) do
    GenServer.call(__MODULE__, {:link_code, code, room_id})
  end

  defp link_code_impl(code, room_id, state) do
    {:reply, :ok, Map.put(state, code, room_id)}
  end

  def remove_code(code) do
    GenServer.call(__MODULE__, {:remove_code, code})
  end

  defp remove_code_impl(code, state) do
    {:reply, :ok, Map.delete(state, code)}
  end

  @impl true
  def init(init) do
    {:ok, init}
  end

  @impl true
  def handle_call({:link_code, code, room_id}, _from, state),
    do: link_code_impl(code, room_id, state)

  def handle_call({:remove_code, code}, _from, state), do: remove_code_impl(code, state)
  def handle_call({:get, code}, _from, state), do: get_impl(code, state)
end
