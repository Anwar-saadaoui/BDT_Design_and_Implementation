from datetime import datetime, timedelta

from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator
from airflow.utils.trigger_rule import TriggerRule

# ---------------------------------------------------------------------------
# Default args applied to every task
# ---------------------------------------------------------------------------

default_args = {
    "owner": "anwar",
    "depends_on_past": False,
    "email_on_failure": False,
    "email_on_retry": False,
    "retries": 2,
    "retry_delay": timedelta(minutes=2),
}
# ---------------------------------------------------------------------------
# Notification helpers (log-based; swap for Slack/email later if you want)
# ---------------------------------------------------------------------------
def notify_success(**context):
    print("=" * 60)
    print("✅ PIPELINE SUCCESS")
    print(f"DAG: {context['dag'].dag_id}")
    print(f"Run ID: {context['run_id']}")
    print(f"Execution date: {context['execution_date']}")
    print("=" * 60)


def notify_failure(context):
    print("=" * 60)
    print("❌ PIPELINE FAILED")
    print(f"Task: {context['task_instance'].task_id}")
    print(f"DAG: {context['dag'].dag_id}")
    print(f"Execution date: {context['execution_date']}")
    print(f"Log URL: {context['task_instance'].log_url}")
    print("=" * 60)


default_args["on_failure_callback"] = notify_failure

# ---------------------------------------------------------------------------
# DAG definition
# ---------------------------------------------------------------------------
with DAG(
    dag_id="real_estate_pipeline",
    description="Bronze -> Silver -> Gold pipeline for real estate listings",
    default_args=default_args,
    schedule_interval="@daily",
    start_date=datetime(2026, 6, 1),
    catchup=False,
    max_active_runs=1,
    tags=["real_estate", "medallion", "dbt", "snowflake"],
) as dag:

    # -----------------------------------------------------------------
    # Task 1 — Load CSV into Snowflake Bronze layer
    # -----------------------------------------------------------------
    load_bronze = BashOperator(
        task_id="load_bronze",
        bash_command=(
            "docker exec bronze_loader "
            "python /app/load_to_snowflake.py "
            "|| (echo 'Bronze load failed' && exit 1)"
        ),
    )

    # -----------------------------------------------------------------
    # Task 2 — Run dbt Silver models
    # -----------------------------------------------------------------
    run_silver = BashOperator(
        task_id="run_dbt_silver",
        bash_command=(
            "cd /opt/airflow && "
            "docker compose run --rm dbt run --select silver "
            "|| (echo 'Silver dbt run failed' && exit 1)"
        ),
    )

    test_silver = BashOperator(
        task_id="test_dbt_silver",
        bash_command=(
            "cd /opt/airflow && "
            "docker compose run --rm dbt test --select silver "
            "|| (echo 'Silver dbt tests failed' && exit 1)"
        ),
    )

    # -----------------------------------------------------------------
    # Task 3 — Run dbt Gold models
    # -----------------------------------------------------------------
    run_gold = BashOperator(
        task_id="run_dbt_gold",
        bash_command=(
            "cd /opt/airflow && "
            "docker compose run --rm dbt run --select gold "
            "|| (echo 'Gold dbt run failed' && exit 1)"
        ),
    )

    test_gold = BashOperator(
        task_id="test_dbt_gold",
        bash_command=(
            "cd /opt/airflow && "
            "docker compose run --rm dbt test --select gold "
            "|| (echo 'Gold dbt tests failed' && exit 1)"
        ),
    )

    # -----------------------------------------------------------------
    # Task 4 — Pipeline end notification
    # -----------------------------------------------------------------
    notify_end = PythonOperator(
        task_id="notify_pipeline_success",
        python_callable=notify_success,
        trigger_rule=TriggerRule.ALL_SUCCESS,
    )

    # -----------------------------------------------------------------
    # DAG dependency order
    # -----------------------------------------------------------------
    load_bronze >> run_silver >> test_silver >> run_gold >> test_gold >> notify_end