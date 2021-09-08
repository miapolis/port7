defmodule Harbor do
  use Application

  require Logger

  @games [:rumble]
  def games(), do: @games

  @config_prune_rooms Application.compile_env!(:harbor, :prune_rooms)
  @config_user_session_timeout Application.compile_env!(:harbor, :user_session_timeout)

  @impl true
  @spec start(any, any) :: {:error, any} | {:ok, pid}
  def start(_type, _args) do
    intro()

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

  @port7 """
                                 dP   d88888P
                                 88       d8'
    88d888b. .d8888b. 88d888b. d8888P    d8'
    88'  `88 88'  `88 88'  `88   88     d8'
    88.  .88 88.  .88 88         88    d8'
    88Y888P' `88888P' dP         dP   d8'
    88
    dP
  """

  defp intro() do
    IO.puts("\n" <> IO.ANSI.bright() <> IO.ANSI.cyan() <> @port7 <> IO.ANSI.reset())

    for i <- 0..75 do
      percentage = i / 75
      filled_count = round(8 * percentage)
      unfilled_count = 8 - filled_count

      left = to_string(Enum.take(["| ", "H ", "A ", "R ", "B ", "O ", "R ", "|"], filled_count))

      right =
        if unfilled_count > 0 do
          for _ <- 0..unfilled_count, into: "", do: " " <> <<Enum.random('!@#$%^&*+-HARBOR')>>
        else
          ""
        end

      IO.write(
        "\r  #{IO.ANSI.cyan() <> IO.ANSI.bright() <> left <> IO.ANSI.reset()}#{IO.ANSI.black_background() <> right <> IO.ANSI.reset()}   "
      )

      :timer.sleep(16)
    end

    config =
      config_opt(:MIX_ENV, Mix.env()) <>
        config_opt(:prune_rooms, @config_prune_rooms) <>
        config_opt(:user_session_timeout, @config_user_session_timeout)

    IO.puts(
      "\n\n> CONFIG#{config}\n#{IO.ANSI.faint()}>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>#{IO.ANSI.reset()}"
    )
  end

  defp config_opt(name, val) do
    "\n|==> " <>
      IO.ANSI.bright() <>
      IO.ANSI.blue() <>
      ":#{name}" <>
      IO.ANSI.reset() <>
      IO.ANSI.black_background() <>
      " -> " <> IO.ANSI.reset() <> IO.ANSI.green() <> "#{val}" <> IO.ANSI.reset()
  end
end
