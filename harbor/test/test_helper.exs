ExUnit.start()

defmodule HarborTest do
  def elixir_module?(module) do
    module
    |> Atom.to_string()
    |> String.starts_with?("Elixir")
  end

  def message_module?(module) do
    exploded = Module.split(module)
    match?(["Pier", "Message", _class, _], exploded)
  end

  def message_validation_module?(module) do
    exploded = Module.split(module)
    match?(["PierTest", "Message", _class, _], exploded)
  end

  def message_test_module?(module) do
    exploded = Module.split(module)
    match?(["PierTest", _class, _], exploded)
  end

  def test_for(module) do
    ["Pier", "Message", class, type] = Module.split(module)
    Module.concat(["PierTest", class, type <> "Test"])
  end

  def validation_for(module) do
    ["Pier", "Message", class, type] = Module.split(module)
    Module.concat(["PierTest", "Message", class, type <> "Test"])
  end
end

if System.argv() == ["test"] do
  ExUnit.after_suite(fn _ ->
    all_elixir_modules =
      :code.all_loaded()
      |> Enum.map(&elem(&1, 0))
      |> Enum.filter(&HarborTest.elixir_module?/1)

    message_modules = Enum.filter(all_elixir_modules, &HarborTest.message_module?/1)

    message_test_modules = Enum.filter(all_elixir_modules, &HarborTest.message_test_module?/1)

    message_validation_modules =
      Enum.filter(all_elixir_modules, &HarborTest.message_validation_module?/1)

    Enum.each(message_modules, fn module ->
      unless (_tm = HarborTest.test_for(module)) in message_test_modules do
        # TODO: Tests for every single message
        # raise "#{inspect(module)} did not have test module #{inspect(tm)}"
      end

      unless (_tm = HarborTest.validation_for(module)) in message_validation_modules do
        # raise "#{inspect(module)} did not have validation module #{inspect(tm)}"
      end
    end)
  end)
end
