defmodule Anchorage.UserSession do
  use GenServer, restart: :temporary

  defmodule State do
    @type t :: %__MODULE__{
            user_id: String.t(),
            ip: String.t(),
            pid: pid()
          }

    defstruct user_id: nil,
              ip: nil,
              pid: nil
  end

  defp via(user_id), do: {:via, Registry, {Anchorage.UserSessionRegistry, user_id}}

  defp cast(user_id, params), do: Generator.cast(via(user_id), params)
  defp call(user_id, params), do: Generator.call(via(user_id), params)

  def start_supervised(values) do
    case DynamicSupervisor.start_child(
           Anchorage.UserSessionDynamicSupervisor,
           {__MODULE__, values}
         ) do
      {:error, {:already_started, pid}} -> {:ignored, pid}
      error -> error
    end
  end

  def count, do: Registry.count(Anchorage.UserSessionRegistry)

  def lookup(user_id), do: Registry.lookup(Anchorage.UserSessionRegistry, user_id)

  def start_link(init) do
    GenServer.start_link(__MODULE__, init, name: via(init[:user_id]))
  end

  def init(init) do
    {:ok, struct(State, init)}
  end
end
