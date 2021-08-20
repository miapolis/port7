defmodule Harbor.Peer do
  @derive {Jason.Encoder, only: [:id]}

  defstruct id: 0

  @type t :: %__MODULE__{
          id: integer()
        }
end
