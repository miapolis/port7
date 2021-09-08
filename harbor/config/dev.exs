use Mix.Config

config :logger, level: :info, backends: [:console]

config :harbor,
  prune_rooms: false,
  user_session_timeout: 5000
