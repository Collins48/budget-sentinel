import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

config :budget_sentinel, BudgetSentinel.Repo,
  username: System.get_env("DB_USERNAME") || "postgres",
  password: System.get_env("DB_PASSWORD") || "postgres",
  hostname: System.get_env("DB_HOST") || "localhost",
  database: System.get_env("DB_NAME") || "budget_sentinel_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

config :budget_sentinel, BudgetSentinelWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "test-only-secret-key-base-0000000000000000000000000000000000",
  server: false

config :budget_sentinel, BudgetSentinel.Notifications.Mailer, adapter: Swoosh.Adapters.Test

config :budget_sentinel, :ai_client, BudgetSentinel.IntelligenceTest.MockAIClient

config :logger, level: :warning

config :phoenix, :plug_init_mode, :runtime
