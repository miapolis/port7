defmodule Harbor.Auth do
  alias Anchorage.UserSession

  @spec authenticate(Pier.Message.Auth.Request.t(), IP.addr()) :: {:ok, term} | {:error, term}
  def authenticate(request, ip) do
    # TODO: do actual authentication
    do_auth(ip, request.userToken, request.nickname)
  end

  def do_auth(ip, user_id, nickname) do
    user_state =
      if length(UserSession.lookup(user_id)) > 0 do
        UserSession.get_state(user_id)
      else
        nil
      end

    {can_auth, current_room_id} =
      if not is_nil(user_state) do
        {user_state.is_disconnected, user_state.current_room_id}
      else
        {true, nil}
      end

    if can_auth do
      user = %{
        user_id: user_id,
        nickname: nickname,
        ip: ip,
        current_room_id: current_room_id,
        peer_id: nil
      }

      # Ensure that a nickname change is made even if a session already exists
      response =
        UserSession.start_supervised(
          user_id: user_id,
          ip: ip,
          nickname: nickname,
          current_room_id: current_room_id
        )

      case response do
        {:ignored, _} ->
          UserSession.set_nickname(user_id, nickname)

        _ ->
          :ok
      end

      UserSession.set_active_ws(user_id, self())
      {:ok, user}
    else
      {:error, "already authenticated"}
    end
  end
end
