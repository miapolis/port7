import EctoEnum

alias Pier.Message.Room
alias Pier.Message.Auth
alias Pier.Message.Misc

defenum(
  Pier.Message.Types.Operator,
  [
    {Room.Create, 1},
    {Misc.Bar, 40},
    {Auth.Request, 73}
  ]
)
