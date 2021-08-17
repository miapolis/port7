defmodule Pier.Message do
  use Ecto.Schema
  alias Ecto.Changeset
  import Changeset

  embedded_schema do
    field(:operator, Pier.Message.Types.Operator, null: false)
    field(:payload, :map)
    field(:reference, :binary_id)
    field(:inbound_operator, :string)
    field(:errors, :map)
  end

  @type t :: %__MODULE__{
          operator: module(),
          payload: map(),
          reference: Harbor.Utils.UUID.t(),
          inbound_operator: String.t()
        }

  @spec changeset(%{String.t() => Pier.json()}, Pier.SocketHandler.state()) :: Changeset.t()
  def changeset(data, state) do
    %__MODULE__{}
    |> cast(data, [:inbound_operator])
    |> Map.put(:params, data)
    |> find(:operator)
    |> find(:payload)
    |> find(:reference, :optional)
    |> cast_operator
    |> cast_reference
    |> cast_inbound_operator
    |> cast_payload(state)
    |> validate_calls_have_references
  end

  @type message_field :: :operator | :payload | :reference

  @valid_forms %{
    operator: ~w(operator op),
    payload: ~w(payload p d),
    reference: ~w(reference ref fetchId)
  }

  defp find(changeset, field, optional \\ false)
  defp find(changeset = %{valid?: false}, _, _), do: changeset

  defp find(changeset, field, optional) when is_atom(field) do
    find(changeset, field, @valid_forms[field], optional)
  end

  @spec find(Changeset.t(), message_field, [String.t()], :optional | false) :: Changeset.t()

  defp find(changeset = %{params: params}, field, [form | _], _)
       when is_map_key(params, form) do
    %{changeset | params: Map.put(changeset.params, "#{field}", params[form])}
  end

  defp find(changeset, field, [_ | rest], optional), do: find(changeset, field, rest, optional)

  defp find(changeset, field, [], optional) do
    if optional do
      changeset
    else
      add_error(changeset, field, "no #{field} present")
    end
  end

  @operators Pier.Message.Manifest.actions()

  defp cast_operator(changeset = %{valid?: false}), do: changeset

  defp cast_operator(changeset = %{params: %{"operator" => op}}) do
    if operator = @operators[op] do
      changeset
      |> put_change(:operator, operator)
      |> put_change(:inbound_operator, op)
    else
      add_error(changeset, :operator, "#{op} is invalid")
    end
  end

  defp cast_reference(changeset = %{valid?: false}), do: changeset

  defp cast_reference(changeset = %{params: %{"reference" => reference}}) do
    put_change(changeset, :reference, reference)
  end

  defp cast_reference(changeset), do: changeset

  defp cast_inbound_operator(changeset) do
    if get_field(changeset, :inbound_operator) do
      changeset
    else
      inbound_operator = get_field(changeset, :operator)
      put_change(changeset, :inbound_operator, inbound_operator)
    end
  end

  defp cast_payload(changeset = %{valid?: false}, _), do: changeset

  defp cast_payload(changeset, state) do
    operator = get_field(changeset, :operator)

    state
    |> operator.initialize()
    |> operator.changeset(changeset.params["payload"])
    |> case do
      inner_changeset = %{valid?: true} ->
        put_change(changeset, :payload, inner_changeset)

      inner_changeset = %{valid?: false} ->
        errors = Harbor.Utils.Errors.changeset_errors(inner_changeset)
        put_change(changeset, :errors, errors)
    end
  end

  defp validate_calls_have_references(changeset = %{valid?: false}), do: changeset

  defp validate_calls_have_references(changeset) do
    operator = get_field(changeset, :operator)

    if function_exported?(operator, :reply_module, 0) do
      validate_required(changeset, [:reference], message: "is required for #{inspect(operator)}")
    else
      changeset
    end
  end

  defimpl Jason.Encoder do
    def encode(message, opts) do
      %{
        op: operator(message),
        p: message.payload
      }
      |> add_reference(message)
      |> add_errors(message)
      |> Jason.Encode.map(opts)
    end

    defp operator(%{operator: op}) when is_binary(op), do: op

    defp operator(%{operator: op}) when is_atom(op) do
      if function_exported?(op, :operator, 0) do
        op.operator()
      end
    end

    defp add_reference(map, %{reference: nil}), do: map
    defp add_reference(map, %{reference: ref}), do: Map.put(map, :ref, ref)

    defp add_errors(map, %{errors: nil}), do: map
    defp add_errors(map, %{errors: e}), do: Map.put(map, :e, e)
  end
end
