defmodule Pier.Message.Room.Kick do
  use Pier.Message.Cast

  @primary_key false
  embedded_schema do
    field(:id, :integer)
  end

  def changeset(initializer \\ %__MODULE__{}, data) do
    initializer
    |> cast(data, [:id])
    |> validate_number(:id, greater_than_or_equal_to: 0)
  end

  def execute(changeset, state) do
    with {:ok, %{id: id}} <- apply_action(changeset, :validate) do
      Harbor.Room.kick_user(state.user.current_room_id, state.user.user_id, id)
      {:noreply, state}
    end
  end
end
