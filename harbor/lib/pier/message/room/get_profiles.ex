defmodule Pier.Message.Room.GetProfiles do
  use Pier.Message.Call

  @primary_key false
  embedded_schema do
  end

  def changeset(initializer \\ %__MODULE__{}, data) do
    initializer
    |> cast(data, [])
  end

  defmodule Reply do
    use Pier.Message.Push

    @derive {Jason.Encoder, only: [:profiles]}

    @primary_key false
    schema "profiles" do
      embeds_many(:profiles, Pier.Message.Types.ManagedPeer)
    end
  end

  def execute(changeset, state) do
    with {:ok, %{}} <- apply_action(changeset, :validate) do
      peers = Harbor.Room.get_profiles(state.user.current_room_id)

      profiles =
        Enum.map(peers, fn {_, peer} ->
          %Pier.Message.Types.ManagedPeer{
            id: peer.id,
            nickname: peer.nickname,
            authMethod: "port7",
            authUsername: "",
            roles: peer.roles
          }
        end)

      {:reply, %Reply{profiles: profiles}, state}
    end
  end
end
