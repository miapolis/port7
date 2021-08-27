defmodule Ports.Rumble.Message.JoinRound do
  use Pier.Message.Cast

  @primary_key false
  embedded_schema do
  end

  def changeset(initializer \\ %__MODULE__{}, data) do
    initializer
    |> cast(data, [])
  end

  def execute(changeset, state) do
    with {:ok, _} <- apply_action(changeset, :validation) do
      Ports.Rumble.Game.join_round(state.user.current_room_id, state.user.peer_id)
      {:noreply, state}
    end
  end
end
