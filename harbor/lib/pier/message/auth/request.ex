defmodule Pier.Message.Auth.Request do
  use Pier.Message.Call
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
  end

  def changeset(intializer \\ %__MODULE__{}, data) do
    intializer
    |> cast(data, [])
    |> validate_required([])
  end

  defmodule Reply do
    use Pier.Message.Push
    @derive {Jason.Encoder, only: []}
    @primary_key false
    embedded_schema do
    end
  end

  def execute(changeset, state) do
    with {:ok, request} <- apply_action(changeset, :validate) do
      {:ok, user} = Harbor.Auth.authenticate(request, state.ip)
      {:reply, %{}, %{state | user: user}}
    else
      _ -> {:close, 4001, "invalid_authentication"}
    end
  end
end
