defmodule Harbor.Auth do
  alias Anchorage.UserSession

  @spec authenticate(Pier.Message.Auth.Request.t(), IP.addr()) :: {:ok, term} | {:error, term}
  def authenticate(request, ip) do
    # TODO: do actual authentication
    do_auth(ip, request.nickname)
  end

  def do_auth(ip, nickname) do
    user_id = Ecto.UUID.generate()

    user = %{
      user_id: user_id,
      nickname: nickname,
      ip: ip,
      current_room_id: nil
    }

    UserSession.start_supervised(user_id: user_id, ip: ip, nickname: nickname)
    UserSession.set_active_ws(user_id, self())
    {:ok, user}
  end
end
