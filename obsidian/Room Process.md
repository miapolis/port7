## Room Process
##### AKA Room Session
This is the basic room process.

Struct information:
```elixir
@type t :: %__MODULE__{
            room_id: String.t(),
            room_name: String.t(),
            room_code: String.t(),
            is_private: String.t(),
            peers: %{String.t() => Harbor.Peer.t()},
            game: atom(),
            inner_game: Quay.BaseGame,
            last_event_timestamp: Habor.U
          }
```

The key idea with the rooms is that they function as an entry point for a room object. Although the room process is not a parent of the chat and game processes, the room has references to both the chat and game process while those two don't really know about each other and don't need to.
