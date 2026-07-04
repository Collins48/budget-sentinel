import Config

config :budget_sentinel, BudgetSentinelWeb.Endpoint,
  cache_static_manifest: "priv/static/cache_manifest.json"

config :logger, level: :info
