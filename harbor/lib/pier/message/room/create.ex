defmodule Pier.Message.Room.Create do
  use Pier.Message.Call, reply: __MODULE__

  @derive {Jason.Encoder, except: [:__meta__]}

  @primary_key {:id, :binary_id, []}
  schema "rooms" do
    field(:name, :string)
    field(:isPrivate, :boolean)
    field(:game, :string)
  end

  @spec changeset(
          {map, map}
          | %{
              :__struct__ => atom | %{:__changeset__ => map, optional(any) => any},
              optional(atom) => any
            },
          :invalid | %{optional(:__struct__) => none, optional(atom | binary) => any}
        ) :: Ecto.Changeset.t()
  def changeset(initializer \\ %__MODULE__{}, data) do
    initializer
    |> cast(data, [:name, :isPrivate, :game])
    |> validate_required([:name, :isPrivate, :game])
    |> validate_length(:name, min: 2, max: 40)
    |> validate_inclusion(:game, Harbor.games())
  end

  def execute(changeset, state) do
    IO.puts("STATE " <> inspect(state))

    with {:ok, room_spec} <- apply_action(changeset, :validation),
         {:ok, %{room: room}} <-
           Harbor.Room.create_room(
             state.user.user_id,
             room_spec.name,
             room_spec.isPrivate,
             room_spec.game
           ) do
      {:reply, struct(__MODULE__, Map.from_struct(room)), state}
    end
  end
end
