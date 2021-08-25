defmodule Harbor.Peer do
  @derive {Jason.Encoder, only: [:id, :nickname, :roles]}

  defstruct id: 0, is_disconnected: false, nickname: "", roles: []

  @type t :: %__MODULE__{
          id: integer(),
          is_disconnected: boolean(),
          nickname: String.t(),
          roles: [atom()]
        }
end
