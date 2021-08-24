import EctoEnum

alias Pier.Message.Chat
alias Pier.Message.Room
alias Pier.Message.Auth
alias Pier.Message.Misc

defenum(
  Pier.Message.Types.Operator,
  [
    {Room.Create, 1},
    {Room.Join, 2},
    {Room.GetProfiles, 3},
    {Chat.Send, 10},
    {Misc.Bar, 40},
    {Auth.Request, 73}
  ]
)
