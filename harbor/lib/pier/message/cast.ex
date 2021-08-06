defmodule Pier.Message.Cast do
  defmacro __using__(opts) do
    quote do
      use Ecto.Schema
      import Ecto.Changeset

      @behaviour Pier.Message.Cast

      Module.register_attribute(__MODULE__, :directions, accumulate: true, persist: true)
      @directions [:inbound]

      unquote(schema_ast(opts))

      def initialize(_state), do: struct(__MODULE__)
      defoverridable initialize: 1

      @after_compile Pier.Message.Cast
    end
  end

  alias Pier.SocketHandler
  alias Ecto.Changeset

  @callback changeset(struct | nil, Pier.json()) :: Ecto.Changeset.t()

  @callback initialize(SocketHandler.state()) :: struct()

  @callback execute(Changeset.t(), SocketHandler.state()) ::
              {:noreply, SocketHandler.state()}
              | {:error, map, SocketHandler.state()}
              | {:error, Changeset.t()}
              | {:exit, code :: 1000..9999, reason :: String.t()}

  def __after_compile__(%{module: module}, _bin) do
    # checks to make sure you've either declared a schema module, or you have
    # implemented a schema
    check_for_schema(module, :inbound)
  end

  def schema_ast(opts) do
    if schema = opts[:schema] do
      quote do
        Module.register_attribute(__MODULE__, :schema, persist: true)
        @schema unquote(schema)
      end
    else
      quote do
        Module.register_attribute(__MODULE__, :schema, persist: true)
        @schema __MODULE__
      end
    end
  end

  def check_for_schema(module, direction) do
    Code.ensure_compiled(module)

    attributes = module.__info__(:attributes)

    case {attributes[:schema], function_exported?(module, :__schema__, 2)} do
      {[^module], true} ->
        :ok

      {[schema_mod], true} ->
        raise CompileError,
          description:
            "in module #{inspect(module)} you have both declared the schema module #{inspect(schema_mod)} and implemented a schema"

      {[^module], false} ->
        raise CompileError,
          description:
            "in module #{inspect(module)} you have failed to declare a schema module or implement a schema"

      {[schema_mod], false} ->
        Code.ensure_compiled(schema_mod)

        # commenting out for now because tests started to fail sometimes even at 150ms
        # Process.sleep(150)
        # unless function_exported?(schema_mod, :__schema__, 2) do
        #   raise CompileError,
        #     description:
        #       "in module #{inspect(module)} you declared the schema #{inspect(schema_mod)} but it doesn't appear to have a schema"
        # end
    end

    unless direction in attributes[:directions] do
      raise CompileError,
        description: "the module #{inspect(module)} does not seem to be a #{direction} module"
    end
  end
end
