defmodule Pier.Message.Misc.Bar do
  use Pier.Message.Call
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field(:bar, :string)
  end

  def changeset(intializer \\ %__MODULE__{}, data) do
    intializer
    |> cast(data, [:bar])
    |> validate_required([:bar])
  end

  defmodule Reply do
    use Pier.Message.Push
    @derive {Jason.Encoder, only: [:message]}
    @primary_key false
    embedded_schema do
      field(:message, :string)
    end
  end

  def execute(changeset, state) do
    case apply_action(changeset, :validate) do
      {:ok, %{bar: bar}} ->
        {:reply, %Reply{message: bar <> " from server"}, state}

      error ->
        error
    end
  end
end
