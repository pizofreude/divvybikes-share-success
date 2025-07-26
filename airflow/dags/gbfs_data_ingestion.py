"""
GBFS Data Ingestion DAG for Divvy Bikeshare
===========================================

This DAG ingests General Bikeshare Feed Specification (GBFS) data from Divvy's API,
focusing on station information and real-time status data to enhance analytics capabilities.

Data Sources:
- Station Information: Static station metadata (daily refresh)
- Station Status: Real-time availability data (every 2 hours)

Storage Strategy:
- Bronze Layer: Raw JSON files with timestamps
- Silver Layer: Processed and validated data
- Gold Layer: Aggregated metrics for analytics

Author: Analytics Engineering Team
Created: July 2025
"""

"""
GBFS Data Ingestion DAG for Divvy Bikeshare - Bronze Layer Only
===============================================================

This DAG ingests General Bikeshare Feed Specification (GBFS) data from Divvy's API
and stores raw data in S3 Bronze layer for downstream processing by dbt.

Data Sources:
- Station Information: Static station metadata (updated as needed)
- Station Status: Real-time availability data 
- System Information: System metadata

Storage Strategy:
- Bronze Layer: Raw JSON files with timestamps and metadata
- Silver/Gold Layers: Handled by dbt transformations (see dbt/README.md)

Author: Analytics Engineering Team
Created: July 2025
"""

from datetime import datetime, timedelta
from typing import Dict, Any, List
import json
import requests
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.amazon.aws.hooks.s3 import S3Hook
from airflow.models import Variable
from airflow.utils.dates import days_ago
import logging

# DAG Configuration
DAG_ID = "gbfs_data_ingestion"
DEFAULT_ARGS = {
    "owner": "analytics-team",
    "depends_on_past": False,
    "start_date": days_ago(1),  # Dynamic start date - always allows current execution
    "email_on_failure": False,
    "email_on_retry": False,
    "retries": 3,
    "retry_delay": timedelta(minutes=5),
    "catchup": False,
}

# GBFS API Configuration
GBFS_BASE_URL = "https://gbfs.lyft.com/gbfs/2.3/chi/en"
GBFS_ENDPOINTS = {
    "station_information": f"{GBFS_BASE_URL}/station_information.json",
    "station_status": f"{GBFS_BASE_URL}/station_status.json",
    "system_information": f"{GBFS_BASE_URL}/system_information.json"
}

# S3 Configuration - Bronze Layer Only
S3_BUCKET = "divvybikes-dev-bronze-96wb3c9c"
S3_BRONZE_PREFIX = "gbfs-data"

def fetch_and_store_gbfs_data(endpoint_name: str, url: str, **context) -> str:
    """
    Fetch data from GBFS API endpoint and store directly in S3 Bronze layer.
    
    Args:
        endpoint_name: Name of the GBFS endpoint
        url: API endpoint URL
        context: Airflow context
        
    Returns:
        S3 key where data was stored
    """
    execution_date = context['execution_date']
    
    logging.info(f"Fetching GBFS data from {endpoint_name}: {url}")
    
    try:
        # Fetch data with timeout
        response = requests.get(url, timeout=30)
        response.raise_for_status()
        
        data = response.json()
        
        # Validate GBFS response structure
        if 'data' not in data:
            raise ValueError(f"Invalid GBFS response structure for {endpoint_name}")
        
        # Count records for logging
        record_count = 0
        if endpoint_name in ['station_information', 'station_status'] and 'stations' in data.get('data', {}):
            record_count = len(data['data']['stations'])
        elif 'data' in data:
            record_count = 1  # System information has single record
            
        # Add metadata for Bronze layer
        enriched_data = {
            "endpoint_name": endpoint_name,
            "fetch_timestamp": execution_date.isoformat(),
            "fetch_date": execution_date.strftime('%Y-%m-%d'),
            "fetch_hour": execution_date.hour,
            "data_timestamp": data.get('last_updated', execution_date.timestamp()),
            "ttl": data.get('ttl', 60),
            "version": data.get('version', '2.3'),
            "record_count": record_count,
            "raw_data": data
        }
        
        # Create partitioned S3 key for Bronze layer
        year = execution_date.year
        month = f"{execution_date.month:02d}"
        day = f"{execution_date.day:02d}"
        hour = f"{execution_date.hour:02d}"
        timestamp = execution_date.strftime('%Y-%m-%d_%H-%M-%S')
        
        # Different partitioning for different endpoints
        if endpoint_name == 'station_status':
            # Hourly partitioning for frequent status updates
            s3_key = f"{S3_BRONZE_PREFIX}/endpoint={endpoint_name}/year={year}/month={month}/day={day}/hour={hour}/{endpoint_name}_{timestamp}.json"
        else:
            # Daily partitioning for station_information and system_information
            s3_key = f"{S3_BRONZE_PREFIX}/endpoint={endpoint_name}/year={year}/month={month}/day={day}/{endpoint_name}_{timestamp}.json"
        
        # Upload to S3 Bronze layer
        s3_hook = S3Hook(aws_conn_id='aws_default')
        json_data = json.dumps(enriched_data, indent=2, ensure_ascii=False)
        
        s3_hook.load_string(
            string_data=json_data,
            key=s3_key,
            bucket_name=S3_BUCKET,
            replace=True
        )
        
        logging.info(f"Successfully stored {endpoint_name} data in Bronze layer:")
        logging.info(f"  - Records: {record_count}")
        logging.info(f"  - S3 Location: s3://{S3_BUCKET}/{s3_key}")
        
        return s3_key
        
    except requests.exceptions.RequestException as e:
        logging.error(f"HTTP error fetching {endpoint_name}: {str(e)}")
        raise
    except json.JSONDecodeError as e:
        logging.error(f"JSON decode error for {endpoint_name}: {str(e)}")
        raise
    except Exception as e:
        logging.error(f"Unexpected error fetching {endpoint_name}: {str(e)}")
        raise

def validate_bronze_data(**context) -> Dict[str, Any]:
    """
    Validate that Bronze layer data was successfully stored.
    
    Args:
        context: Airflow context
        
    Returns:
        Validation report
    """
    execution_date = context['execution_date']
    
    try:
        s3_hook = S3Hook(aws_conn_id='aws_default')
        
        # Check for expected files in Bronze layer
        year = execution_date.year
        month = f"{execution_date.month:02d}"
        day = f"{execution_date.day:02d}"
        hour = f"{execution_date.hour:02d}"
        
        validation_report = {
            "validation_timestamp": execution_date.isoformat(),
            "validation_date": execution_date.strftime('%Y-%m-%d'),
            "endpoints_validated": [],
            "overall_status": "PASS"
        }
        
        for endpoint_name in GBFS_ENDPOINTS.keys():
            endpoint_report = {
                "endpoint_name": endpoint_name,
                "bronze_file_exists": False,
                "status": "PASS"
            }
            
            # Check Bronze layer based on endpoint partitioning
            if endpoint_name == 'station_status':
                bronze_prefix = f"{S3_BRONZE_PREFIX}/endpoint={endpoint_name}/year={year}/month={month}/day={day}/hour={hour}"
            else:
                bronze_prefix = f"{S3_BRONZE_PREFIX}/endpoint={endpoint_name}/year={year}/month={month}/day={day}"
                
            try:
                bronze_objects = s3_hook.list_keys(bucket_name=S3_BUCKET, prefix=bronze_prefix)
                endpoint_report["bronze_file_exists"] = len(bronze_objects) > 0
                
                if endpoint_report["bronze_file_exists"]:
                    logging.info(f"✅ {endpoint_name}: Bronze file found")
                else:
                    logging.warning(f"❌ {endpoint_name}: No Bronze file found")
                    endpoint_report["status"] = "FAIL"
                    validation_report["overall_status"] = "FAIL"
                    
            except Exception as e:
                logging.error(f"Error checking {endpoint_name}: {str(e)}")
                endpoint_report["bronze_file_exists"] = False
                endpoint_report["status"] = "FAIL"
                validation_report["overall_status"] = "FAIL"
            
            validation_report["endpoints_validated"].append(endpoint_report)
        
        logging.info(f"Bronze layer validation completed: {validation_report['overall_status']}")
        
        # Log summary
        if validation_report["overall_status"] == "PASS":
            logging.info("🎉 All GBFS data successfully stored in Bronze layer")
            logging.info("📋 Next steps: dbt transformations will process this data into Silver/Gold layers")
        else:
            logging.error("❌ Some GBFS endpoints failed validation")
            
        return validation_report
        
    except Exception as e:
        logging.error(f"Error in Bronze layer validation: {str(e)}")
        raise

# Create DAG
dag = DAG(
    DAG_ID,
    default_args=DEFAULT_ARGS,
    description="Ingest GBFS data to S3 Bronze layer for Divvy bikeshare analytics (dbt handles Silver/Gold)",
    schedule_interval=None,  # Manual trigger initially
    max_active_runs=1,
    tags=["gbfs", "divvy", "bikeshare", "bronze-layer", "ingestion"]
)

# Task 1: Fetch and Store Station Information
fetch_station_info_task = PythonOperator(
    task_id="fetch_store_station_information",
    python_callable=fetch_and_store_gbfs_data,
    op_kwargs={
        "endpoint_name": "station_information",
        "url": GBFS_ENDPOINTS["station_information"]
    },
    dag=dag
)

# Task 2: Fetch and Store Station Status
fetch_station_status_task = PythonOperator(
    task_id="fetch_store_station_status",
    python_callable=fetch_and_store_gbfs_data,
    op_kwargs={
        "endpoint_name": "station_status",
        "url": GBFS_ENDPOINTS["station_status"]
    },
    dag=dag
)

# Task 3: Fetch and Store System Information
fetch_system_info_task = PythonOperator(
    task_id="fetch_store_system_information",
    python_callable=fetch_and_store_gbfs_data,
    op_kwargs={
        "endpoint_name": "system_information",
        "url": GBFS_ENDPOINTS["system_information"]
    },
    dag=dag
)

# Task 4: Validate Bronze Layer Data
validate_bronze_task = PythonOperator(
    task_id="validate_bronze_layer",
    python_callable=validate_bronze_data,
    dag=dag
)

# Define task dependencies - all fetch tasks run in parallel, then validation
[fetch_station_info_task, fetch_station_status_task, fetch_system_info_task] >> validate_bronze_task
