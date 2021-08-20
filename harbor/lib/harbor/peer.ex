defmodule Harbor.Peer do
  @derive {Jason.Encoder, only: [:id, :nickname]}

  defstruct id: 0, nickname: ""

  @type t :: %__MODULE__{
          id: integer(),
          nickname: String.t()
        }
end
