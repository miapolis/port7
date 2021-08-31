defmodule Quay.Utils.Time do
  def ms_now() do
    :os.system_time(:millisecond)
  end
end
