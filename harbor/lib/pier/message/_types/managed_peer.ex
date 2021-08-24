defmodule Pier.Message.Types.ManagedPeer do
  use Ecto.Schema

  @derive {Jason.Encoder, only: [:id, :nickname, :authMethod, :authUsername, :roles]}

  @primary_key false
  embedded_schema do
    field(:id, :integer)
    field(:nickname, :string)
    field(:authMethod, :string)
    field(:authUsername, :string)
    field(:roles, {:array, :string})
  end
end
