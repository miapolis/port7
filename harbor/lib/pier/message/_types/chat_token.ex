defmodule Pier.Message.Types.ChatToken do
  use Ecto.Schema

  @message_character_limit 100

  @primary_key false
  embedded_schema do
    field(:type, Pier.Message.Types.ChatTokenType)
    field(:value, :string, default: "")
  end

  defimpl Jason.Encoder do
    def encode(%{type: type, value: value}, opts) do
      Jason.Encode.map(
        %{
          t: type,
          v: value
        },
        opts
      )
    end
  end

  import Ecto.Changeset

  def changeset(changeset, %{"t" => type, "v" => value}) do
    changeset(changeset, %{"type" => type, "value" => value})
  end

  def changeset(changeset, data) do
    changeset
    |> cast(data, [:type, :value])
    |> validate_required([:type])
    |> validate_length(:value, min: 0, max: @message_character_limit)
    |> validate_link
  end

  defp validate_link(changeset) do
    if get_change(changeset, :type) == :link do
      validate_link_uri(changeset)
    else
      changeset
    end
  end

  @allowed_schemes ["http", "https"]
  defp validate_link_uri(changeset) do
    uri =
      changeset
      |> get_change(:value)
      |> URI.parse()

    if match?(
         %{host: host, scheme: scheme}
         when is_binary(host) and scheme in @allowed_schemes,
         uri
       ) do
      changeset
    else
      add_error(changeset, :value, "invalid url")
    end
  end
end
