defmodule Harbor do
  use Application

  require Logger

  @games [:rumble]
  def games(), do: @games

  @impl true
  def start(_type, _args) do
    Logger.info("Starting port7...")
    Logger.info("MAIN PROCESS PID " <> inspect(self()))

    children = [
      Anchorage.Supervisors.UserSession,
      Anchorage.Supervisors.RoomSession,
      Anchorage.Supervisors.Chat,
      Anchorage.Supervisors.Game,
      Anchorage.RoomCode,
      {Phoenix.PubSub, name: Anchorage.PubSub},
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug: Broth,
        options: [
          port: String.to_integer(System.get_env("PORT") || "4001"),
          dispatch: dispatch(),
          protocol_options: [idle_timeout: :infinity]
        ]
      )
    ]

    opts = [strategy: :one_for_one, name: Harbor.Supervisor]

    Supervisor.start_link(children, opts)
  end

  defp dispatch do
    [
      {:_,
       [
         {"/socket", Pier.SocketHandler, []},
         {:_, Plug.Cowboy.Handler, {Pier, []}}
       ]}
    ]
  end
end
