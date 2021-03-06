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

    @derive {Jason.Encoder, only: [:name, :isPrivate, :myPeerId, :myRoles, :peers]}

    @primary_key false
    schema "rooms" do
      field(:name, :string)
      field(:myPeerId, :integer)
      field(:myRoles, {:array, :string})
      embeds_many(:peers, Pier.Message.Types.Peer)
      field(:isPrivate, :boolean)
    end
  end

  def execute(changeset, state) do
    with {:ok, %{roomId: room_id}} <- apply_action(changeset, :validate) do
      case Harbor.Room.join_room(room_id, state.user.user_id) do
        %{error: error} ->
          case error do
            :full ->
              {:reply, %{error: "room is full"}, state}

            _ ->
              {:error, error, state}
          end

        %{room: room, peer: peer} ->
          user = %{state.user | current_room_id: room.room_id, peer_id: peer.id}
          peers = Map.values(room.peers)

          {:reply,
           %Reply{
             name: room.room_name,
             isPrivate: room.is_private,
             myPeerId: peer.id,
             myRoles: peer.roles,
             peers: peers
           }, %{state | user: user}}
      end
    end
  end
end
