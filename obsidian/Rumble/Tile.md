## Tile
##### A tile is the basic unit of a Rumble game
Struct information:
```elixir
@type t :: %__MODULE__{
	id: integer(),
	x: integer(),
	y: integer(),
	group_id: integer(),
	group_index: integer()
}
```

Tiles may optinally b·e listed as a child to a [[Group]]

