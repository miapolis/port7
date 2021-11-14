import EctoEnum

alias Pier.Message.Chat
alias Pier.Message.Room
alias Pier.Message.Auth
alias Pier.Message.Misc

alias Ports.Rumble

defenum(
  Pier.Message.Types.Operator,
  [
    # COMMON 1-100
    {Room.Create, 1},
    {Room.Join, 2},
    {Room.GetProfiles, 3},
    {Room.Kick, 4},
    {Chat.Send, 10},
    {Misc.Bar, 40},
    {Auth.Request, 73},
    # RUMBLE 2xx
    {Rumble.Message.JoinRound, 200},
    {Rumble.Message.LeaveRound, 201},
    {Rumble.Message.MoveTile, 202},
    {Rumble.Message.MoveGroup, 203}
  ]
)
