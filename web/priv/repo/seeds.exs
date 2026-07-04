alias BudgetSentinel.{Accounts, Ministries, Procurement}

:rand.seed(:exsplus, {42, 42, 42})

sectors = ~w(infrastructure education health water energy)

ministries_by_sector =
  for {sector, name, code} <- [
        {"infrastructure", "Ministry of Infrastructure", "MININFRA"},
        {"education", "Ministry of Education", "MINEDUC"},
        {"health", "Ministry of Health", "MINISANTE"},
        {"water", "Ministry of Water and Sanitation", "MINIWASA"},
        {"energy", "Ministry of Energy", "MINENERGY"}
      ],
      into: %{} do
    {:ok, ministry} = Ministries.create_ministry(%{name: name, code: code})
    {sector, ministry}
  end

if is_nil(Accounts.get_user_by_email("admin@budgetsentinel.local")) do
  {:ok, _admin} =
    Accounts.create_user_by_admin(%{
      email: "admin@budgetsentinel.local",
      password: "ChangeMe123456!",
      role: "admin"
    })

  IO.puts("Bootstrap admin created: admin@budgetsentinel.local / ChangeMe123456!")
end

for {_sector, ministry} <- ministries_by_sector do
  slug = ministry.code |> String.downcase()

  for {role, prefix} <- [{"auditor", "auditor"}, {"oversight_officer", "oversight"}] do
    email = "#{prefix}.#{slug}@budgetsentinel.local"

    if is_nil(Accounts.get_user_by_email(email)) do
      Accounts.create_user_by_admin(%{
        email: email,
        password: "ChangeMe123456!",
        role: role,
        ministry_id: ministry.id
      })
    end
  end
end

contractors = [
  "Kivu Builders Ltd",
  "Nyandungu Construction",
  "Akagera Civil Works",
  "Virunga Engineering",
  "Muhabura Contractors",
  "Inyenyeri Health Systems",
  "Rusizi Roadworks",
  "Gisozi Education Partners"
]

milestones = ~w(site_preparation foundation structural_works finishing handover)

random_date = fn ->
  Date.add(~D[2024-01-01], :rand.uniform(364))
end

project_name = fn sector, index ->
  "#{String.capitalize(sector)} Project ##{index}"
end

projects =
  for index <- 1..50 do
    sector = Enum.random(sectors)
    budget = Float.round(50_000 + :rand.uniform() * 1_950_000, 2)
    completion = Float.round(10 + :rand.uniform() * 90, 1)
    benchmark = Float.round(budget * (0.85 + :rand.uniform() * 0.25), 2)

    {:ok, project} =
      Procurement.create_project(%{
        name: project_name.(sector, index),
        sector: sector,
        ministry_id: ministries_by_sector[sector].id,
        approved_budget: Decimal.from_float(budget),
        market_benchmark: Decimal.from_float(benchmark),
        completion_rate: Decimal.from_float(completion),
        milestones: milestones
      })

    project
  end

create_expenditure = fn project, amount, milestone ->
  Procurement.create_expenditure(%{
    project_id: project.id,
    contractor: Enum.random(contractors),
    amount: Decimal.from_float(Float.round(amount * 1.0, 2)),
    milestone: milestone,
    paid_on: random_date.()
  })
end

# 190 normal expenditures: 2-18% of the project's approved budget
for _ <- 1..190 do
  project = Enum.random(projects)
  budget = Decimal.to_float(project.approved_budget)
  fraction = 0.02 + :rand.uniform() * 0.16
  create_expenditure.(project, budget * fraction, Enum.random(milestones))
end

# 10 embedded fraud scenarios across the 5 known procurement irregularity types

# Budget overrun x2 — payment pushes cumulative spend well past approved budget
for project <- Enum.take_random(projects, 2) do
  budget = Decimal.to_float(project.approved_budget)
  create_expenditure.(project, budget * (1.3 + :rand.uniform() * 0.3), "finishing")
end

# Duplicate payment x2 — same contractor paid twice for the same milestone
for project <- Enum.take_random(projects, 2) do
  budget = Decimal.to_float(project.approved_budget)
  contractor = Enum.random(contractors)
  milestone = Enum.random(milestones)
  amount = budget * (0.2 + :rand.uniform() * 0.1)

  Enum.each(1..2, fn _ ->
    Procurement.create_expenditure(%{
      project_id: project.id,
      contractor: contractor,
      amount: Decimal.from_float(Float.round(amount, 2)),
      milestone: milestone,
      paid_on: random_date.()
    })
  end)
end

# Ghost project x2 — full payment disbursed against zero project completion
for project <- Enum.take_random(projects, 2) do
  {:ok, _} =
    project
    |> Ecto.Changeset.change(completion_rate: Decimal.new("0"))
    |> BudgetSentinel.Repo.update()

  budget = Decimal.to_float(project.approved_budget)
  create_expenditure.(project, budget * (0.4 + :rand.uniform() * 0.2), "handover")
end

# Inflated contract x2 — payment far above the project's market benchmark
for project <- Enum.take_random(projects, 2) do
  benchmark = Decimal.to_float(project.market_benchmark || project.approved_budget)
  create_expenditure.(project, benchmark * (1.8 + :rand.uniform() * 0.4), "structural_works")
end

# Premature payment x2 — large payment released far ahead of reported completion
for project <- Enum.take_random(projects, 2) do
  budget = Decimal.to_float(project.approved_budget)
  create_expenditure.(project, budget * (0.55 + :rand.uniform() * 0.2), "foundation")
end

IO.puts("Seeded #{length(projects)} projects with simulated Rwanda expenditure data,")
IO.puts("including 10 embedded fraud scenarios across 5 procurement irregularity types.")
