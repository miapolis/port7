defmodule PortsTest.Rumble.Game.Turn do
  use ExUnit.Case

  alias Ports.Rumble.Game

  # Creates a joined peer
  defp jp(id) do
    %{id: id, is_joined: true}
  end

  defp nil_state(peers) do
    %{milestone: %{current_turn: nil}, peers: peers}
  end

  defp do_next(state) do
    %{state | milestone: %{current_turn: Game.next_turn(state)}}
  end

  test "validate first turn is first id" do
    peers = %{0 => jp(0), 1 => jp(1)}
    state = nil_state(peers)
    state = do_next(state)

    assert state.milestone.current_turn == 0

    # The current turn should be the first id and the peer that is
    # not joined should be filtered out
    peers = %{0 => %{id: 0, is_joined: false}, 1 => jp(1), 2 => jp(2)}
    state = nil_state(peers)
    state = do_next(state)

    assert state.milestone.current_turn == 1

    # Validate sorting
    peers = %{0 => %{id: 0, is_joined: false}, 4 => jp(4), 2 => jp(2)}
    state = nil_state(peers)
    state = do_next(state)

    assert state.milestone.current_turn == 2
  end

  test "validate continue" do
    peers = %{0 => jp(0), 1 => %{id: 1, is_joined: false}, 2 => jp(2)}
    state = nil_state(peers)

    state = do_next(state)
    assert state.milestone.current_turn == 0

    # Skip the first player because they are not in the game
    state = do_next(state)
    assert state.milestone.current_turn == 2
  end

  test "validate loopback" do
    peers = %{0 => jp(0), 1 => jp(1)}
    state = nil_state(peers)

    state = do_next(state)
    assert state.milestone.current_turn == 0

    state = do_next(state)
    assert state.milestone.current_turn == 1

    state = do_next(state)
    assert state.milestone.current_turn == 0

    # Ensure this works when the first player is not id 0
    peers = %{0 => %{id: 0, is_joined: false}, 1 => jp(1), 2 => jp(2)}
    state = nil_state(peers)

    state = do_next(state)
    assert state.milestone.current_turn == 1

    state = do_next(state)
    assert state.milestone.current_turn == 2

    state = do_next(state)
    assert state.milestone.current_turn == 1
  end
end
