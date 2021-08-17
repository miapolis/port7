defmodule Anchorage.Supervisors.RoomSession do
  use Supervisor

  def start_link(init) do
    Supervisor.start_link(__MODULE__, init)
  end

  @impl true
  def init(_init) do
    children = [
      {Registry, keys: :unique, name: Anchorage.RoomSessionRegistry},
      {DynamicSupervisor, name: Anchorage.RoomSessionDynamicSupervisor, strategy: :one_for_one}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
