defmodule Pier.Message.Call do
  alias Pier.Message.Cast

  defmacro __using__(opts) do
    default_reply_module = Module.concat(__CALLER__.module, Reply)

    reply_module =
      opts
      |> Keyword.get(:reply, default_reply_module)
      |> Macro.expand(__CALLER__)

    directions =
      if reply_module == __CALLER__.module do
        [:inbound, :outbound]
      else
        [:inbound]
      end

    quote do
      use Ecto.Schema
      import Ecto.Changeset

      @behaviour Pier.Message.Call

      Module.register_attribute(__MODULE__, :directions, accumulate: true, persist: true)
      @directions unquote(directions)

      unquote(Cast.schema_ast(opts))

      @impl true
      def reply_module, do: unquote(reply_module)

      @impl true
      def initialize(_state), do: struct(__MODULE__)

      defoverridable initialize: 1

      # verify compile-time guarantees
      @after_compile Pier.Message.Call
    end
  end

  alias Ecto.Changeset
  alias Pier.SocketHandler

  @callback reply_module() :: module
  @callback execute(Changeset.t(), SocketHandler.state()) ::
              {:reply, map, SocketHandler.state()}
              | {:noreply, SocketHandler.state()}
              | {:error, map, SocketHandler.state()}
              | {:error, Changeset.t()}
              | {:close, code :: 1000..9999, reason :: String.t()}

  @callback initialize(SocketHandler.state()) :: struct

  @callback changeset(struct | nil, Pier.json()) :: Ecto.Changeset.t()

  def __after_compile__(%{module: module}, _bin) do
    # checks to make sure you've either declared a schema module, or you have
    # implemented a schema
    Cast.check_for_schema(module, :inbound)

    # checks to make sure the declared reply module actually exists.
    reply_module = module.reply_module()
    Code.ensure_compiled(reply_module)

    Cast.check_for_schema(reply_module, :outbound)
  end
end
