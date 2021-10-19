defmodule Harbor.Utils.SimpleId do
  @doc """
  ### Generates the first simple id integer given a map with integer keys.
  #### Examples
  ```
  gen(%{}) # 0
  gen(%{0 => "foo"}) # 1
  gen(%{1 => "foo"}) # 0
  gen(%{0 => "foo", 1 => "bar"}) # 2
  gen(%{0 => "foo", 2 => "bar"}) # 1
  ```
  """
  @spec gen(%{integer() => any()}) :: integer()
  def gen(existing) when is_map(existing) do
    gen(Map.keys(existing))
  end

  @spec gen([integer()]) :: integer()
  def gen(existing) when is_list(existing) do
    Enum.reduce_while(0..(Enum.count(existing) + 1), 0, fn x, acc ->
      if !Enum.member?(existing, x) do
        {:halt, x}
      else
        {:cont, acc}
      end
    end)
  end
end
