defmodule Harbor.MixProject do
  use Mix.Project

  def project do
    [
      app: :harbor,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      name: "Harbor",
      source_url: "https://github.com/miapolis/port7",
      homepage_url: "https://github.com/miapolis/port7",
      docs: [
        main: "Harbor",
        source_url_pattern: "https://github.com/miapolis/port7/blob/main/harbor/%{path}#L%{line}"
      ]
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
      {:hackney, "~> 1.8"},
      {:vapor, "~> 0.10"},
      # TEST HELPERS
      {:faker, "~> 0.15.0", only: :test},
      {:websockex, "~> 0.4.3", only: :test},
      # EX_DOC
      {:ex_doc, "~> 0.24", only: :dev, runtime: false}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/_support"]
  defp elixirc_paths(_), do: ["lib"]
end
