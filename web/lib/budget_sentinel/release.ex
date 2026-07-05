defmodule BudgetSentinel.Release do
  @moduledoc """
  Migration and seed tasks runnable from a compiled release.
  """

  @app :budget_sentinel

  def migrate do
    for repo <- repos() do
      {:ok, _, _} =
        Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def seed do
    Application.load(@app)

    path = Application.app_dir(@app, "priv/repo/seeds.exs")

    for repo <- repos() do
      {:ok, _, _} =
        Ecto.Migrator.with_repo(repo, fn _repo ->
          Code.eval_file(path)
        end)
    end
  end

  def seed do
    Application.load(@app)
    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, fn repo ->
        count = repo.aggregate(BudgetSentinel.Ministries.Ministry, :count)
        if count == 0 do
          seeds_path =
            :code.priv_dir(@app)
            |> to_string()
            |> Path.join("repo/seeds.exs")

          if File.exists?(seeds_path) do
            IO.puts("[seed] Running seeds from #{seeds_path}")
            Code.eval_file(seeds_path)
            IO.puts("[seed] Done.")
          else
            IO.puts("[seed] Seeds file not found at #{seeds_path}, skipping.")
          end
        else
          IO.puts("[seed] Database already seeded (#{count} ministries found), skipping.")
        end
      end)
    end
  end

  def rollback(repo, version) do
    {:ok, _, _} =
      Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp repos do
    Application.load(@app)
    Application.fetch_env!(@app, :ecto_repos)
  end
end