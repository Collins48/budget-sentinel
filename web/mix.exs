defmodule BudgetSentinel.MixProject do
  use Mix.Project

  def project do
    [
      app: :budget_sentinel,
      version: "0.1.0",
      elixir: "~> 1.17",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  def application do
    [
      mod: {BudgetSentinel.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:phoenix, "~> 1.7.14"},
      {:phoenix_live_view, "~> 1.0"},
      {:phoenix_pubsub, "~> 2.1"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_reload, "~> 1.5", only: :dev},
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:bcrypt_elixir, "~> 3.0"},
      {:ecto_sql, "~> 3.11"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_ecto, "~> 4.5"},
      {:swoosh, "~> 1.16"},
      {:gen_smtp, "~> 1.2"},
      {:req, "~> 0.5"},
      {:finch, "~> 0.19"},
      {:jason, "~> 1.4"},
      {:bandit, "~> 1.5"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.1"},
      {:mox, "~> 1.1", only: :test}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["esbuild.install --if-missing"],
      "assets.build": ["esbuild default"],
      "assets.deploy": ["esbuild default --minify", "phx.digest"]
    ]
  end
end
