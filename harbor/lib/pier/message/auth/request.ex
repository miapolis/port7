defmodule Pier.Message.Auth.Request do
  use Pier.Message.Call
  import Ecto.Changeset

  require Logger

  @primary_key false
  embedded_schema do
    field(:nickname, :string)
    field(:userToken, :string)
  end

  def changeset(intializer \\ %__MODULE__{}, data) do
    intializer
    |> cast(data, [:nickname, :userToken])
    |> validate_required([:nickname, :userToken])
    |> validate_length(:nickname, min: 2, max: 20)
    |> validate_length(:userToken, is: 16)
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
      case Harbor.Auth.authenticate(request, state.ip) do
        {:ok, user} ->
          Logger.debug("AUTH " <> inspect user)
          {:reply, %{}, %{state | user: user}}

        {:error, reason} ->
          Logger.debug("Auth failed: " <> reason)
          {:reply, %{error: reason}, state}
      end
    else
      _ -> {:close, 4001, "invalid_authentication"}
    end
  end
end
