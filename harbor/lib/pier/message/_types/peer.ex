defmodule Pier.Message.Types.Peer do
  use Ecto.Schema

  @derive {Jason.Encoder, only: [:id, :nickname]}

  @primary_key false
  embedded_schema do
    field(:id, :integer)
    field(:nickname, :string)
  end
end
