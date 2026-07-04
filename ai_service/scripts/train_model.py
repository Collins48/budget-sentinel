import os
import random
import sys
from datetime import date, timedelta

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.config import Config
from app.domain.entities import ExpenditureRecord, ProjectContext
from app.ml import feature_engineering
from app.ml.isolation_forest_model import train_isolation_forest
from app.ml.model_store import save_model

SECTORS = ["infrastructure", "education", "health", "water", "energy"]
CONTRACTORS = [
    "Kivu Builders Ltd",
    "Nyandungu Construction",
    "Akagera Civil Works",
    "Virunga Engineering",
    "Muhabura Contractors",
    "Inyenyeri Health Systems",
    "Rusizi Roadworks",
    "Gisozi Education Partners",
]
MILESTONES = ["site_preparation", "foundation", "structural_works", "finishing", "handover"]

random.seed(42)


def _random_date(start_year: int = 2024) -> str:
    start = date(start_year, 1, 1)
    offset = random.randint(0, 364)
    return (start + timedelta(days=offset)).isoformat()


def generate_projects(count: int = 50) -> list:
    projects = []
    for index in range(count):
        sector = random.choice(SECTORS)
        budget = round(random.uniform(50_000, 2_000_000), 2)
        completion = round(random.uniform(10, 100), 1)
        projects.append(
            ProjectContext(
                id=f"PRJ-{index + 1:03d}",
                sector=sector,
                approved_budget=budget,
                completion_rate=completion,
                market_benchmark=round(budget * random.uniform(0.85, 1.1), 2),
            )
        )
    return projects


def generate_expenditures(projects: list, normal_count: int = 190) -> list:
    expenditures = []
    for index in range(normal_count):
        project = random.choice(projects)
        fraction = random.uniform(0.02, 0.18)
        amount = round(project.approved_budget * fraction, 2)
        expenditures.append(
            ExpenditureRecord(
                id=f"EXP-{index + 1:04d}",
                project_id=project.id,
                contractor=random.choice(CONTRACTORS),
                amount=amount,
                milestone=random.choice(MILESTONES),
                date=_random_date(),
            )
        )
    return expenditures


def inject_fraud_scenarios(projects: list, expenditures: list, start_index: int) -> list:
    fraud_records = []
    next_id = start_index

    def new_id() -> str:
        nonlocal next_id
        next_id += 1
        return f"EXP-{next_id:04d}"

    # Budget overrun x2
    for project in random.sample(projects, 2):
        fraud_records.append(
            ExpenditureRecord(
                id=new_id(),
                project_id=project.id,
                contractor=random.choice(CONTRACTORS),
                amount=round(project.approved_budget * random.uniform(1.3, 1.6), 2),
                milestone="finishing",
                date=_random_date(),
            )
        )

    # Duplicate payment x2 (same contractor + milestone paid twice)
    for project in random.sample(projects, 2):
        contractor = random.choice(CONTRACTORS)
        milestone = random.choice(MILESTONES)
        amount = round(project.approved_budget * random.uniform(0.2, 0.3), 2)
        for _ in range(2):
            fraud_records.append(
                ExpenditureRecord(
                    id=new_id(),
                    project_id=project.id,
                    contractor=contractor,
                    amount=amount,
                    milestone=milestone,
                    date=_random_date(),
                )
            )

    # Ghost project x2: zero-completion project receiving large payment
    ghost_projects = []
    for project in random.sample(projects, 2):
        ghost_project = ProjectContext(
            id=project.id,
            sector=project.sector,
            approved_budget=project.approved_budget,
            completion_rate=0.0,
            market_benchmark=project.market_benchmark,
        )
        ghost_projects.append(ghost_project)
        fraud_records.append(
            ExpenditureRecord(
                id=new_id(),
                project_id=project.id,
                contractor=random.choice(CONTRACTORS),
                amount=round(project.approved_budget * random.uniform(0.4, 0.6), 2),
                milestone="handover",
                date=_random_date(),
            )
        )

    # Inflated contract x2: amount far above market benchmark
    for project in random.sample(projects, 2):
        benchmark = project.market_benchmark or project.approved_budget
        fraud_records.append(
            ExpenditureRecord(
                id=new_id(),
                project_id=project.id,
                contractor=random.choice(CONTRACTORS),
                amount=round(benchmark * random.uniform(1.8, 2.2), 2),
                milestone="structural_works",
                date=_random_date(),
            )
        )

    # Premature payment x2: large payment against low completion
    for project in random.sample(projects, 2):
        fraud_records.append(
            ExpenditureRecord(
                id=new_id(),
                project_id=project.id,
                contractor=random.choice(CONTRACTORS),
                amount=round(project.approved_budget * random.uniform(0.55, 0.75), 2),
                milestone="foundation",
                date=_random_date(),
            )
        )

    return fraud_records, ghost_projects


def main() -> None:
    config = Config.from_env()

    projects = generate_projects(50)
    normal_expenditures = generate_expenditures(projects, normal_count=190)
    fraud_expenditures, ghost_projects = inject_fraud_scenarios(
        projects, normal_expenditures, start_index=len(normal_expenditures)
    )

    project_lookup = {project.id: project for project in projects}
    for ghost_project in ghost_projects:
        project_lookup[ghost_project.id] = ghost_project

    all_expenditures = normal_expenditures + fraud_expenditures

    feature_matrix = feature_engineering.build_feature_matrix(project_lookup, all_expenditures)
    model = train_isolation_forest(feature_matrix, config.isolation_forest_contamination)
    save_model(model, config.model_path)

    print(f"Trained Isolation Forest on {len(all_expenditures)} expenditure records")
    print(f"({len(projects)} projects, {len(fraud_expenditures)} embedded fraud records)")
    print(f"Model saved to {config.model_path}")


if __name__ == "__main__":
    main()
