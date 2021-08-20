defmodule AnchorageTest.Room do
  use ExUnit.Case

  alias Harbor.Room

  test "validate new peer id" do
    # When no one is in the room we expect peer 0
    state = %{peers: %{}}
    assert Room.gen_peer_id(state) == 0
    # If peer 0 is already in the room we expect peer 1
    state = %{peers: %{"foo" => %{id: 0}}}
    assert Room.gen_peer_id(state) == 1
    # If peer 0 left we expect peer 0 to be replaced
    state = %{peers: %{"foo" => %{id: 1}}}
    assert Room.gen_peer_id(state) == 0
    # When a third peer joins we expect 2
    state = %{peers: %{"foo" => %{id: 0}, "bar" => %{id: 1}}}
    assert Room.gen_peer_id(state) == 2
    # When a peer in the middle leaves, their id is to be replaced
    state = %{peers: %{"foo" => %{id: 0}, "bar" => %{id: 2}}}
    assert Room.gen_peer_id(state) == 1

    state = %{peers: %{"foo" => %{id: 0}, "bar" => %{id: 1}, "baz" => %{id: 2}}}
    assert Room.gen_peer_id(state) == 3
  end
end
