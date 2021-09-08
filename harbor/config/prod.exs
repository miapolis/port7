use Mix.Config

config :sentry,
  dsn:
    System.get_env("SENTRY_DSN") || System.get_env("SENTRY_DNS") ||
      raise("""
      environment variable SENTRY_DSN is missing.
      """),
  environment_name: :prod,
  enable_source_code_context: true,
  root_source_code_path: File.cwd!(),
  included_environments: [:prod]

config :logger, level: :info, backends: [:console, Sentry.LoggerBackend]

config :harbor,
  prune_rooms: true,
  user_session_timeout: 60000
