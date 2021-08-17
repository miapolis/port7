defmodule Harbor.Chat do
  def send_msg(ws_state, payload) do
    case ws_state.user.current_room_id do
      nil ->
        :noop

      room_id ->
        Anchorage.Chat.send_msg(room_id, payload)
    end
  end
end
