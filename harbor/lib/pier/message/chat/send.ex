defmodule Pier.Message.Chat.Send do
  use Pier.Message.Cast
  alias Pier.Message.Types.ChatToken

  @message_character_limit 100

  @derive {Jason.Encoder, only: [:id, :tokens, :from, :sentAt, :nickname]}

  @primary_key false
  embedded_schema do
    field(:id, :binary_id)
    embeds_many(:tokens, ChatToken)
    field(:from, :binary_id)
    field(:nickname, :string)
    field(:sentAt, :utc_datetime)
  end

  @impl true
  def initialize(state) do
    %__MODULE__{
      id: UUID.uuid4(),
      from: state.user.user_id,
      nickname: state.user.nickname,
      sentAt: DateTime.utc_now()
    }
  end

  @impl true
  def changeset(initializer \\ %__MODULE__{}, data) do
    initializer
    |> cast(data, [])
    |> put_tokens(data["tokens"])
  end

  def put_tokens(changeset, []) do
    add_error(changeset, :tokens, "must not be empty")
  end

  def put_tokens(changeset, tokens) when is_list(tokens) do
    {embedded_tokens, acc_length} =
      Enum.map_reduce(tokens, 0, &apply_changeset_accumulate_length/2)

    if acc_length == 0 do
      throw(tokens: {"no empty messages", []})
    end

    put_embed(changeset, :tokens, embedded_tokens)
  rescue
    _ in Ecto.CastError ->
      add_error(changeset, :tokens, "is invalid")
  catch
    errors ->
      %{changeset | errors: errors ++ changeset.errors, valid?: false}
  end

  def put_tokens(changeset, _invalid_tokens) do
    add_error(changeset, :tokens, "is invalid")
  end

  defp apply_changeset_accumulate_length(token, length) do
    changeset = ChatToken.changeset(%ChatToken{}, token)
    new_length = length + text_size(changeset)

    case {changeset.valid?, new_length <= @message_character_limit} do
      {false, _} ->
        throw(changeset.errors)

      {true, false} ->
        throw(tokens: {"combined length too long", []})

      {true, true} ->
        :ok
    end

    {changeset, new_length}
  end

  defp text_size(changeset) do
    changeset
    |> get_field(:value)
    |> :erlang.byte_size()
  end

  @impl true
  def execute(changeset, state) do
    with {:ok, payload} <- apply_action(changeset, :validate) do
      Harbor.Chat.send_msg(state, payload)
      {:noreply, state}
    end
  end
end
