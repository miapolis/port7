use Mix.Config

config :harbor,
  api_url: System.get_env("API_URL") || "http://localhost:4001"
