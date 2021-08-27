defmodule Quay.BaseGame do
  # @spec peer_join(any(), Harbor.Peer.t()) :: any()
  # def peer_join(room_id, peer)

  # @spec peer_leave(any(), Harbor.Peer.t()) :: any()
  # def peer_leave(room_id, peer)

  # @spec peer_remove(any(), Harbor.Peer.t()) :: any()
  # def peer_remove(room_id, peer)

  @callback peer_join(any(), any(), Harbor.Peer.t()) :: any()

  @callback peer_leave(any(), Harbor.Peer.t()) :: any()

  @callback peer_remove(any(), Harbor.Peer.t()) :: any()
end
