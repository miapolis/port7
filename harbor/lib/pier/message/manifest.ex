defmodule Pier.Message.Manifest do
  alias Pier.Message.Misc

  alias Pier.Message.Types.Operator
  require Operator

  @actions %{
    "foo:bar" => Misc.Bar
  }

  @actions
  |> Map.values()
  |> Enum.each(fn module ->
    Operator.valid_value?(module) ||
      raise CompileError,
        description: "the module #{inspect(module)} is not a member of #{inspect(Operator)}"
  end)

  def actions, do: @actions
end
