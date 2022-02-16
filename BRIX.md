## Brix

Right now, Brix is being mainly used for creating tests quickly. Available commands for brix include:

### Harbor (Port7's Elixir API)

#### Tests

- pier_room_ws_op: `brix harbor pier_room_ws_op port7 {module}`
  - 'module' corresponds to the name of the Pier room message to generate a template for.
    If the module was 'ban', the template generated would be to test the 'room:ban' ws message
- ports_ws_op: `brix harbor ports_ws_op {game} {module}`
  - 'game' corresponds to the name of the game that the message belongs to i.e. 'rumble'.
    If the module was 'join_round', the template generated would be to test the 'rumble:join_round' ws message
