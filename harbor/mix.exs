defmodule Harbor.MixProject do
  use Mix.Project

  def project do
    [
      app: :harbor,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Harbor, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug_cowboy, "~> 2.5"},
      {:phoenix_pubsub, "~> 2.0.0"},
      {:jason, "~> 1.2"},
      {:ecto_enum, "~> 1.4"},
      {:elixir_uuid, "~> 1.2"},
      {:expletive, "~> 0.1.0"},
      {:fsmx, "~> 0.2.0"},
      {:sentry, "~> 8.0"},
      {:hackney, "~> 1.8"}
    ]
  end
end
