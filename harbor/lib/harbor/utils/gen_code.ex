defmodule Habor.Utils.GenCode do
  # 6 might be necessary in the future (~456976 current codes)
  @room_code_size 4
  @config Expletive.configure(blacklist: Expletive.Blacklist.english())

  @spec room_code :: binary
  def room_code() do
    code = for _ <- 1..@room_code_size, into: "", do: String.upcase(<<Enum.random(?a..?z)>>)
    # There is a small chance the room code will be a profane English word with four letters
    if Expletive.profane?(code, @config) do
      room_code()
    end

    code
  end
end
