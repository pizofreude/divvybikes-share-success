"""
File: airflow/dags/dbt_transformation_dag.py
---------------------------------------------
Airflow DAG for dbt Divvy Bikes Transformation Pipeline
Orchestrates the Bronze → Silver → Gold → Marts transformation workflow

start_task >> clean_dbt >> install_deps >> test_connection >> check_freshness
                ↓             ↓
           dbt clean      dbt deps
        (clean slate)  (install packages)
"""

from datetime import datetime, timedelta
from airflow import DAG
from airflow.providers.postgres.operators.postgres import PostgresOperator
from airflow.providers.bash.operators.bash import BashOperator
from airflow.operators.dummy import DummyOperator

# Default arguments
default_args = {
    'owner': 'pizofreude',
    'depends_on_past': False,
    'start_date': datetime(2024, 1, 1),
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 2,
    'retry_delay': timedelta(minutes=5),
    'catchup': False
}

# Create DAG
dag = DAG(
    'dbt_divvy_transformation',
    default_args=default_args,
    description='dbt transformation pipeline for Divvy Bikes data',
    schedule_interval='@daily',  # Run daily after data ingestion
    max_active_runs=1,
    tags=['dbt', 'divvy', 'transformation', 'medallion']
)

# Start task
start_task = DummyOperator(
    task_id='start_transformation_pipeline',
    dag=dag
)

# Clean dbt artifacts FIRST (before installing dependencies)
# CRITICAL: dbt clean removes dbt_packages/, so must run BEFORE dbt deps
clean_dbt = BashOperator(
    task_id='clean_dbt_artifacts',
    bash_command='cd /opt/airflow/dbt_divvy && dbt clean',
    dag=dag
)

# Install dbt dependencies AFTER cleaning
# This ensures packages are available for all subsequent dbt commands
install_deps = BashOperator(
    task_id='install_dbt_dependencies',
    bash_command='cd /opt/airflow/dbt_divvy && dbt deps',
    dag=dag
)

# Test dbt connection
test_connection = BashOperator(
    task_id='test_dbt_connection',
    bash_command='cd /opt/airflow/dbt_divvy && dbt debug',
    dag=dag
)

# Check source data freshness
check_freshness = BashOperator(
    task_id='check_source_freshness',
    bash_command='cd /opt/airflow/dbt_divvy && dbt source freshness',
    dag=dag,
    # Allow this to fail if data is not fresh
    trigger_rule='all_success'
)

# === SILVER LAYER ===
run_silver_trips = BashOperator(
    task_id='run_silver_trips_cleaned',
    bash_command='cd /opt/airflow/dbt_divvy && dbt run --models trips_cleaned',
    dag=dag
)

run_silver_weather = BashOperator(
    task_id='run_silver_weather_cleaned',
    bash_command='cd /opt/airflow/dbt_divvy && dbt run --models weather_cleaned',
    dag=dag
)

run_silver_stations = BashOperator(
    task_id='run_silver_stations_cleaned',
    bash_command='cd /opt/airflow/dbt_divvy && dbt run --models stations_cleaned',
    dag=dag
)

test_silver = BashOperator(
    task_id='test_silver_layer',
    bash_command='cd /opt/airflow/dbt_divvy && dbt test --models trips_cleaned weather_cleaned stations_cleaned',
    dag=dag
)

# === GOLD LAYER ===
run_gold_trips_enhanced = BashOperator(
    task_id='run_gold_trips_enhanced',
    bash_command='cd /opt/airflow/dbt_divvy && dbt run --models trips_enhanced',
    dag=dag
)

run_gold_station_performance = BashOperator(
    task_id='run_gold_station_performance',
    bash_command='cd /opt/airflow/dbt_divvy && dbt run --models station_performance',
    dag=dag
)

run_gold_behavioral_analysis = BashOperator(
    task_id='run_gold_behavioral_analysis',
    bash_command='cd /opt/airflow/dbt_divvy && dbt run --models behavioral_analysis',
    dag=dag
)

test_gold = BashOperator(
    task_id='test_gold_layer',
    bash_command='cd /opt/airflow/dbt_divvy && dbt test --models trips_enhanced station_performance behavioral_analysis',
    dag=dag
)

# === MARTS LAYER ===
run_marts = BashOperator(
    task_id='run_business_marts',
    bash_command='cd /opt/airflow/dbt_divvy && dbt run --models conversion_opportunities',
    dag=dag
)

test_marts = BashOperator(
    task_id='test_business_marts',
    bash_command='cd /opt/airflow/dbt_divvy && dbt test --models conversion_opportunities',
    dag=dag
)

# Generate documentation
generate_docs = BashOperator(
    task_id='generate_dbt_documentation',
    bash_command='cd /opt/airflow/dbt_divvy && dbt docs generate',
    dag=dag
)

# Final comprehensive tests
run_final_tests = BashOperator(
    task_id='run_comprehensive_tests',
    bash_command='cd /opt/airflow/dbt_divvy && dbt test',
    dag=dag
)

# End task
end_task = DummyOperator(
    task_id='transformation_pipeline_complete',
    dag=dag
)

# === TASK DEPENDENCIES ===

# Pipeline start - CORRECT ORDER: clean first, then install deps
start_task >> clean_dbt >> install_deps >> test_connection >> check_freshness

# Silver layer (can run in parallel after setup is complete)
check_freshness >> [run_silver_trips, run_silver_weather, run_silver_stations]

# Test silver layer after all silver models complete
[run_silver_trips, run_silver_weather, run_silver_stations] >> test_silver

# Gold layer (depends on silver layer completion)
test_silver >> run_gold_trips_enhanced
test_silver >> run_gold_station_performance
test_silver >> run_gold_behavioral_analysis

# Test gold layer
[run_gold_trips_enhanced, run_gold_station_performance, run_gold_behavioral_analysis] >> test_gold

# Business marts (depends on gold layer)
test_gold >> run_marts >> test_marts

# Documentation and final tests
test_marts >> generate_docs
test_marts >> run_final_tests

# Pipeline completion
[generate_docs, run_final_tests] >> end_task
