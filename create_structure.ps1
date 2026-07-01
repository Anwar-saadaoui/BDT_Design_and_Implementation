# Project Structure Generator (creates inside current folder, with .gitkeep)

$folders = @(
    "data\raw",
    "bronze\sql",
    "dbt_project\models\silver",
    "dbt_project\models\gold",
    "dbt_project\macros",
    "dbt_project\tests",
    "dbt_project\seeds",
    "airflow\dags",
    "airflow\plugins",
    "airflow\logs",
    "powerbi\screenshots",
    "docs",
    "scripts"
)

$files = @(
    "README.md",
    "notes.md",
    ".env.example",
    ".gitignore",
    "data\raw\real_estate_listings.csv",
    "bronze\load_to_snowflake.py",
    "bronze\sql\create_bronze_table.sql",
    "bronze\requirements.txt",
    "dbt_project\dbt_project.yml",
    "dbt_project\profiles.yml.example",
    "dbt_project\models\silver\silver_listings.sql",
    "dbt_project\models\silver\schema.yml",
    "dbt_project\models\silver\sources.yml",
    "dbt_project\models\gold\dim_property.sql",
    "dbt_project\models\gold\dim_location.sql",
    "dbt_project\models\gold\dim_time.sql",
    "dbt_project\models\gold\dim_energy_rating.sql",
    "dbt_project\models\gold\fact_listings.sql",
    "dbt_project\models\gold\schema.yml",
    "dbt_project\macros\clean_price.sql",
    "airflow\dags\real_estate_pipeline_dag.py",
    "airflow\docker-compose.yml",
    "powerbi\RealEstate_Dashboard.pbix",
    "docs\cahier_des_charges.md",
    "docs\architecture_diagram.png",
    "docs\dimensional_model_justification.md",
    "docs\data_dictionary.md",
    "scripts\run_pipeline_local.sh"
)

# Create folders
foreach ($folder in $folders) {
    New-Item -ItemType Directory -Path $folder -Force | Out-Null
}

# Create files
foreach ($file in $files) {
    New-Item -ItemType File -Path $file -Force | Out-Null
}

# Add .gitkeep to every folder
foreach ($folder in $folders) {
    New-Item -ItemType File -Path "$folder\.gitkeep" -Force | Out-Null
}

Write-Host "Project structure created in current folder (with .gitkeep files)" -ForegroundColor Green