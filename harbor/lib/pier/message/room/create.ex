defmodule Pier.Message.Room.Create do
  use Pier.Message.Call, reply: __MODULE__

  @derive {Jason.Encoder, only: [:id, :code, :name, :isPrivate, :game]}

  @primary_key {:id, :binary_id, []}
  schema "rooms" do
    field(:name, :string)
    field(:isPrivate, :boolean)
    field(:game, :string)
  end

  def changeset(initializer \\ %__MODULE__{}, data) do
    initializer
    |> cast(data, [:name, :isPrivate, :game])
    |> validate_required([:name, :isPrivate, :game])
    |> validate_length(:name, min: 2, max: 40)
    |> validate_inclusion(:game, Harbor.games())
  end

  def execute(changeset, state) do
    with {:ok, room_spec} <- apply_action(changeset, :validation),
         {:ok, %{room: room}} <-
           Harbor.Room.create_room(
             room_spec.name,
             room_spec.isPrivate,
             room_spec.game
           ) do
      {:reply, room, state}
    end
  end
end
