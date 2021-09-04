defmodule Quay.BaseGame do
  # GENERAL

  @callback start_link_supervised(any()) :: any()

  # PEER OPERATIONS

  @callback peer_join(any(), any(), Harbor.Peer.t()) :: any()

  @callback peer_leave(any(), Harbor.Peer.t()) :: any()

  @callback peer_remove(any(), Harbor.Peer.t()) :: any()
end
