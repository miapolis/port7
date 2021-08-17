defmodule Harbor.Auth do
  alias Anchorage.UserSession

  @spec authenticate(Pier.Message.Auth.Request.t(), IP.addr()) :: {:ok, term} | {:error, term}
  def authenticate(_request, ip) do
    # TODO: do actual authentication
    do_auth(ip)
  end

  def do_auth(ip) do
    user_id = Ecto.UUID.generate()

    user = %{
      user_id: user_id,
      ip: ip
    }

    UserSession.start_supervised(user_id: user_id, ip: ip)
    UserSession.set_active_ws(user_id, self())
    {:ok, user}
  end
end
