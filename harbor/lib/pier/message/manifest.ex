defmodule Pier.Message.Manifest do
  alias Pier.Message.Room
  alias Pier.Message.Chat
  alias Pier.Message.Misc
  alias Pier.Message.Auth

  alias Ports.Rumble

  alias Pier.Message.Types.Operator
  require Operator

  @actions %{
    "room:create" => Room.Create,
    "room:join" => Room.Join,
    "room:get_profiles" => Room.GetProfiles,
    "room:kick" => Room.Kick,
    "chat:send_msg" => Chat.Send,
    "foo:bar" => Misc.Bar,
    "auth:request" => Auth.Request,
    # RUMBLE
    "rumble:join_round" => Rumble.Message.JoinRound,
    "rumble:leave_round" => Rumble.Message.LeaveRound,
    "rumble:move_tile" => Rumble.Message.MoveTile
  }

  @actions
  |> Map.values()
  |> Enum.each(fn module ->
    Operator.valid_value?(module) ||
      raise CompileError,
        description: "the module #{inspect(module)} is not a member of #{inspect(Operator)}"
  end)

  def actions, do: @actions
end
