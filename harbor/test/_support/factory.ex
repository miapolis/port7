defmodule HarborTest.Support.Factory do
  @allowed_characters 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-'
  @token_length 16
  @spec user_token() :: String.t()
  def user_token() do
    for _ <- 1..@token_length, into: "", do: <<Enum.random(@allowed_characters)>>
  end
end
