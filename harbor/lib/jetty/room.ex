defmodule Jetty.Room do
  use Ecto.Schema

  @derive {Jason.Encoder,
           only: [
             :id,
             :code,
             :name,
             :isPrivate,
             :game
           ]}

  @type t :: %__MODULE__{
          id: Ecto.UUID.t(),
          code: String.t(),
          name: String.t(),
          isPrivate: boolean(),
          users: [String.t()],
          game: String.t()
        }

  @primary_key false
  schema "rooms" do
    field(:id, :string)
    field(:code, :string)
    field(:name, :string)
    field(:isPrivate, :string)
    field(:users, {:array, :string})
    field(:game, :string)
  end
end
