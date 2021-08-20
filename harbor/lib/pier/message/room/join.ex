defmodule Pier.Message.Room.Join do
  use Pier.Message.Call
  alias Harbor.Utils.UUID

  @primary_key false
  embedded_schema do
    field(:roomId, :binary_id)
  end

  def changeset(initializer \\ %__MODULE__{}, data) do
    initializer
    |> cast(data, [:roomId])
    |> validate_required([:roomId])
    |> UUID.normalize(:roomId)
  end

  defmodule Reply do
    use Pier.Message.Push

    @derive {Jason.Encoder, only: [:name, :isPrivate, :myPeerId, :peers]}

    @primary_key false
    schema "rooms" do
      field(:name, :string)
      field(:myPeerId, :integer)
      embeds_many(:peers, Pier.Message.Types.Peer)
      field(:isPrivate, :boolean)
    end
  end

  def execute(changeset, state) do
    IO.inspect(state)

    with {:ok, %{roomId: room_id}} <- apply_action(changeset, :validate) do
      case Harbor.Room.join_room(room_id, state.user.user_id) do
        %{error: error} ->
          {:error, error, state}

        %{room: room, peer_id: peer_id} ->
          user = %{state.user | current_room_id: room.room_id}
          peers = Map.values(room.peers)

          {:reply,
           %Reply{
             name: room.room_name,
             isPrivate: room.is_private,
             myPeerId: peer_id,
             peers: peers
           }, %{state | user: user}}
      end
    end
  end
end
