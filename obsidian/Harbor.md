## Harbor
##### Harbor is Port7's Elixir API backend.
The goal of the backend is to serve these purposes:
- Create and provide [[Room]]s on demand, which contain the following additional processes
	- [[Chat Process]]
	- [[Game Process]] 
- Display a list of public rooms
- [[Room Pruning]]
- Manage the [[Room Session]] registry and [[User Session]] registry
- Generate [[Room Codes]]for rooms
- Provide a REST API for joining rooms