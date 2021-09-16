use Mix.Config

config :logger, level: :none

config :harbor,
  api_url: System.get_env("API_URL") || "http://localhost:4001",
  user_session_timeout: 60000,
  prune_rooms: true
