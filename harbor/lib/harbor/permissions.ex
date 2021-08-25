defmodule Harbor.Permissions do
  def can_manage_members?(roles) do
    Enum.member?(roles, :leader)
  end
end
