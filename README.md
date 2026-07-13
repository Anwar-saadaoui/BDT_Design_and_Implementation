# 🏠 Real Estate Data Pipeline — Medallion Architecture

End-to-end data engineering pipeline for real estate listings, built with **Snowflake**, **dbt**, **Apache Airflow**, and **Docker** — following the Bronze → Silver → Gold medallion architecture, feeding a **Power BI** dashboard.

> Academic project — Projet Fil Rouge (BDT — Big Data Technologies)

---

## 📐 Architecture Overview

```
CSV (raw listings)
       │
       ▼
┌─────────────┐     Python script      ┌────────────────────┐
│   Bronze    │ ◄───────────────────── │ load_to_snowflake.py│
│  (raw data) │                         └────────────────────┘
└─────────────┘
       │
       │  dbt (cleaning, typing, dedup, outlier removal)
       ▼
┌─────────────┐
│   Silver    │  → SILVER.SILVER_LISTINGS (1 clean table)
│  (cleaned)  │
└─────────────┘
       │
       │  dbt (dimensional modeling — Star Schema)
       ▼
┌──────────────┐
│    Gold      │  → dim_property, dim_location, dim_time,
│ (star schema)│     dim_energy_rating, fact_listings
└──────────────┘
       │
       ▼
┌─────────────┐
│  Power BI   │  Direct connection to Gold layer
│  Dashboard  │  (3 pages — Market Overview, Price Analysis,
└─────────────┘   Property Characteristics)
```

The entire pipeline is orchestrated by **Apache Airflow**, running everything inside **Docker containers**.

---

## 🗂️ Project Structure

```
BDT_Design_and_Implementation/
├── airflow/
│   ├── dags/real_estate_pipeline_dag.py    # Orchestration DAG
│   ├── logs/                               # gitignored, runtime logs
│   ├── plugins/
│   └── Dockerfile
├── bronze/
│   ├── load_to_snowflake.py                # CSV -> Bronze loader
│   ├── sql/create_bronze_table.sql
│   ├── Dockerfile
│   └── requirements.txt
├── data/
│   └── raw/real_estate_listings.csv        # Source CSV
├── dbt_project/
│   ├── models/
│   │   ├── silver/
│   │   │   ├── silver_listings.sql
│   │   │   ├── schema.yml
│   │   │   └── sources.yml
│   │   └── gold/
│   │       ├── dim_property.sql
│   │       ├── dim_location.sql
│   │       ├── dim_time.sql
│   │       ├── dim_energy_rating.sql
│   │       ├── fact_listings.sql
│   │       └── schema.yml
│   ├── macros/
│   │   ├── clean_price.sql
│   │   ├── clean_property_type.sql
│   │   └── generate_schema_name.sql
│   ├── seeds/
│   ├── snapshots/
│   ├── target/                             # gitignored, compiled artifacts
│   ├── logs/                               # gitignored
│   ├── Dockerfile
│   ├── dbt_project.yml
│   ├── packages.yml
│   └── profiles.yml                        # gitignored — see setup below
├── powerbi/
│   ├── RealEstate_Dashboard.pbix
│   └── screenshots/
├── docs/
│   ├── cahier_des_charges.md
│   ├── architecture_diagram.png
│   ├── dimensional_model_justification.md
│   └── data_dictionary.md
├── scripts/
│   └── run_pipeline_local.sh
├── docker-compose.yml                      # Root orchestration file
├── .env                                    # gitignored — Snowflake credentials
├── .gitignore
├── notes.md                                # data quality issues log
└── README.md
```

---

## 🧱 Medallion Layers

### Bronze — Raw

- CSV loaded as-is into Snowflake, **all columns as `STRING`**
- Adds `LOAD_TIMESTAMP` metadata column for full traceability
- Table: `BRONZE.RAW_LISTINGS`

### Silver — Cleaned

Built with dbt. Handles all data quality issues identified in the source CSV:

| Issue | Fix |
|---|---|
| Missing values | Retained as `NULL`, documented (not silently dropped) |
| Duplicates | `ROW_NUMBER()` deduped by `listing_id`, most recent `LOAD_TIMESTAMP` kept |
| Price as text (`"150000 EUR"`) | Custom macro `clean_price()` strips non-numeric chars, casts to `NUMBER` |
| Inconsistent date formats | `COALESCE` across 8 date format patterns (`YYYY-MM-DD`, `DD/MM/YYYY`, `DD.MM.YYYY`, etc.) |
| Broken spacing in `property_type` | Custom macro `clean_property_type()` normalizes via regex + fuzzy matching |
| Inconsistent parking/heating values | Standardized via `clean_yes_no()` macro and `CASE` mapping |
| Outliers (unrealistic price/surface) | Filtered: price 1,000–50,000,000 / surface 5–2,000 m² |

Derived columns added: `price_per_m2`, `property_age`

Table: `SILVER.SILVER_LISTINGS`

### Gold — Star Schema

Dimensional model chosen: **Star Schema** (see [justification](docs/dimensional_model_justification.md))

| Table | Description |
|---|---|
| `dim_property` | property_type, condition, heating_type, has_parking |
| `dim_location` | country, city, neighborhood |
| `dim_time` | year, quarter, month, day, week — derived from `listing_date` |
| `dim_energy_rating` | A–G rating + efficiency category |
| `fact_listings` | Measures (price, surface_m2, price_per_m2, property_age) + FKs to all dims |

---

## ⚙️ Orchestration — Apache Airflow

DAG: `real_estate_pipeline` (`airflow/dags/real_estate_pipeline_dag.py`)

```
load_bronze → run_dbt_silver → test_dbt_silver → run_dbt_gold → test_dbt_gold → notify_success
```

- **Retries**: 2 automatic retries per task, 2-minute delay between retries
- **Error handling**: each task fails loudly with clear error propagation; `on_failure_callback` logs failure details (task, DAG, execution date, log URL)
- **Logs**: searchable per-task in the Airflow UI, also persisted to `airflow/logs/`
- **Schedule**: `@daily` (configurable), manual trigger also supported via the UI

---

## 🚀 Setup & Installation

### Prerequisites

- Docker Desktop (with WSL2 backend on Windows)
- A Snowflake account with `ACCOUNTADMIN` (or equivalent) role
- Git

### 1. Clone the repository

```bash
git clone https://github.com/Anwar-saadaoui/BDT_Design_and_Implementation.git
cd BDT_Design_and_Implementation
```

### 2. Configure Snowflake credentials

Create a `.env` file at the project root (never commit this):

```env
SNOWFLAKE_ACCOUNT=your_account_identifier
SNOWFLAKE_USER=your_user
SNOWFLAKE_PASSWORD=your_password
SNOWFLAKE_ROLE=your_role
SNOWFLAKE_DATABASE=REAL_ESTATE_DB
SNOWFLAKE_WAREHOUSE=COMPUTE_WH
SNOWFLAKE_SCHEMA=PUBLIC
```

### 3. Configure dbt profile

Create `dbt_project/profiles.yml` (gitignored, uses env vars — no real secrets stored):

```yaml
real_estate_pipeline:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: "{{ env_var('SNOWFLAKE_ACCOUNT') }}"
      user: "{{ env_var('SNOWFLAKE_USER') }}"
      password: "{{ env_var('SNOWFLAKE_PASSWORD') }}"
      role: "{{ env_var('SNOWFLAKE_ROLE') }}"
      database: "{{ env_var('SNOWFLAKE_DATABASE') }}"
      warehouse: "{{ env_var('SNOWFLAKE_WAREHOUSE') }}"
      schema: "{{ env_var('SNOWFLAKE_SCHEMA') }}"
      threads: 4
```

### 4. Build and start all containers

```bash
docker compose up -d --build
```

This starts: `postgres` (Airflow metadata DB), `airflow-webserver`, `airflow-scheduler`, `bronze_loader`, and builds the `dbt-snowflake` image.

### 5. Access Airflow UI

Open [http://localhost:8080](http://localhost:8080) — login `admin` / `admin`

Toggle the `real_estate_pipeline` DAG **ON**, then trigger it manually (▶ button) to run the full pipeline end to end.

---

## 🧪 Running Components Individually (for development)

```bash
# Test Snowflake connection
docker compose run --rm dbt debug

# Run Silver layer only
docker compose run --rm dbt run --select silver

# Run Gold layer only
docker compose run --rm dbt run --select gold

# Run everything Silver + downstream (Gold included)
docker compose run --rm dbt run --select silver+

# Run tests
docker compose run --rm dbt test --select silver
docker compose run --rm dbt test --select gold

# Generate and view dbt docs
docker compose run --rm dbt docs generate
```

---

## 📊 Power BI Dashboard

Connects **directly to Snowflake's Gold layer** (no CSV import) — 3 pages:

| Page | Focus |
|---|---|
| **Market Overview** | Total listings, avg price, avg surface, distribution by country/property type, global country filter |
| **Price Analysis** | Price by country/city, median price/m² by property type, price distribution, price trend over time |
| **Property Characteristics** | Surface distribution, energy class distribution, avg property age by country, parking proportion, summary table by city |

File: `powerbi/RealEstate_Dashboard.pbix`

---

## 🐛 Troubleshooting Notes (issues we actually hit)

| Problem | Cause | Fix |
|---|---|---|
| `TRY_CAST cannot be used with arguments of types NUMBER and TIMESTAMP_NTZ` | `LOAD_TIMESTAMP` stored as `NUMBER` in Bronze, not string | Cast through string first: `TRY_CAST(LOAD_TIMESTAMP::string AS TIMESTAMP_NTZ)` |
| `No profile specified in dbt_project.yml` | Missing `profile:` key | Add `profile: 'real_estate_pipeline'` to `dbt_project.yml` |
| `no profiles.yml found` | Volume mount path issue on Windows (`~` doesn't expand reliably) | Use `DBT_PROFILES_DIR: /usr/app/dbt` env var instead of mounting `~/.dbt` |
| `Deprecated test arguments` on `accepted_values` | dbt-core 2.0.0-alpha syntax change | Nest values under `arguments:` key in `schema.yml` |
| Nulls in `listing_date` after cleaning | Two date formats (`DD.MM.YYYY`, `MM-DD-YYYY`) not covered by `COALESCE` | Added both formats + their reverse counterparts to the date parsing chain |
| Git blocking branch checkout | `dbt_project/target/`, `dbt_project/logs/`, `airflow/logs/` were tracked in Git (change on every run) | Added to `.gitignore`, ran `git rm -r --cached` to untrack |

---

## 👥 Team & Git Workflow

- Group of 4, each member owns a dedicated branch:
  - `feature/bronze-loading`
  - `feature/silver-cleaning`
  - `feature/gold-dimensional`
  - `feature/airflow-orchestration`
- All merges to `main` go through Pull Requests, validated by at least one other team member
- Commits kept clear and regular throughout development

---

## 📅 Timeline

- **Assigned**: 29.06.2026
- **Deadline**: 10.07.2026

---

## 📄 Related Documentation

- [Cahier des Charges](docs/cahier_des_charges.md)
- [Dimensional Model Justification](docs/dimensional_model_justification.md)
- [Data Dictionary](docs/data_dictionary.md)
- [Data Quality Notes](notes.md)
