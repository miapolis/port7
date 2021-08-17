defmodule Anchorage.Supervisors.Chat do
  use Supervisor

  def start_link(init) do
    Supervisor.start_link(__MODULE__, init)
  end

  @impl true
  def init(_init) do
    children = [
      {Registry, keys: :unique, name: Anchorage.RoomChatRegistry},
      {DynamicSupervisor, name: Anchorage.RoomChatDynamicSupervisor, strategy: :one_for_one}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
