$folders = @(
    "dbt_project\models\silver",
    "dbt_project\models\gold",
    "dbt_project\macros",
    "dbt_project\tests\generic",
    "dbt_project\seeds",
    "dbt_project\snapshots",
    "dbt_project\analyses",
    "dbt_project\logs",
    "dbt_project\target"
)

$files = @(
    "dbt_project\Dockerfile",
    "dbt_project\dbt_project.yml",
    "dbt_project\packages.yml",
    "dbt_project\.dbtignore",
    "dbt_project\models\silver\sources.yml",
    "dbt_project\models\silver\silver_listings.sql",
    "dbt_project\models\silver\schema.yml",
    "dbt_project\models\gold\dim_property.sql",
    "dbt_project\models\gold\dim_location.sql",
    "dbt_project\models\gold\dim_time.sql",
    "dbt_project\models\gold\dim_energy_rating.sql",
    "dbt_project\models\gold\fact_listings.sql",
    "dbt_project\models\gold\schema.yml",
    "dbt_project\macros\clean_price.sql",
    "dbt_project\macros\clean_property_type.sql",
    "dbt_project\macros\generate_schema_name.sql",
    "dbt_project\tests\generic\assert_positive_price.sql",
    "dbt_project\seeds\country_reference.csv"
)

foreach ($folder in $folders) {
    New-Item -ItemType Directory -Path $folder -Force | Out-Null
}
foreach ($file in $files) {
    New-Item -ItemType File -Path $file -Force | Out-Null
}
foreach ($folder in @("dbt_project\snapshots","dbt_project\analyses","dbt_project\logs","dbt_project\target")) {
    New-Item -ItemType File -Path "$folder\.gitkeep" -Force | Out-Null
}

Write-Host "dbt_project structure created" -ForegroundColor Green