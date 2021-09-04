defmodule Harbor.Utils.Time do
  def ms_now() do
    :os.system_time(:millisecond)
  end

  def s_now() do
    :os.system_time(:second)
  end
end
