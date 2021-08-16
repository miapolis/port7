defmodule Anchorage.Supervisors.UserSession do
  use Supervisor

  def start_link(init) do
    Supervisor.start_link(__MODULE__, init)
  end

  @spec init(any) :: {:ok, {%{intensity: any, period: any, strategy: any}, list}}
  def init(_init) do
    children = [
      {Registry, keys: :unique, name: Anchorage.UserSessionRegistry},
      {DynamicSupervisor, name: Anchorage.UserSessionDynamicSupervisor, strategy: :one_for_one}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
