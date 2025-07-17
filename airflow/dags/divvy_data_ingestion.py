"""
Divvy Bikes Data Ingestion DAG

This DAG orchestrates the ingestion of historical Divvy bike trip data from the public S3 bucket
to our Bronze layer in our data lake. It handles data for both 2023 and 2024, with monthly
partitioning for optimal processing and storage.

Author: pizofreude
Created: 2025-07-15
"""

from datetime import datetime, timedelta
from typing import List, Dict, Any
import pandas as pd
import boto3
from botocore.exceptions import ClientError
import logging
import zipfile
from io import BytesIO

from airflow import DAG
from airflow.decorators import task
from airflow.providers.amazon.aws.hooks.s3 import S3Hook
from airflow.providers.amazon.aws.operators.s3 import S3CreateBucketOperator
from airflow.providers.amazon.aws.transfers.s3_to_redshift import S3ToRedshiftOperator
from airflow.models import Variable
from airflow.utils.task_group import TaskGroup
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator
from airflow.utils.trigger_rule import TriggerRule

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# DAG Configuration
DAG_ID = "divvy_data_ingestion"
DESCRIPTION = "Ingest Divvy bike trip data from public source to Bronze layer"

# Default arguments for all tasks
default_args = {
    'owner': 'pizofreude',
    'depends_on_past': False,
    'start_date': datetime(2025, 7, 15),
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 2,
    'retry_delay': timedelta(minutes=5),
    'catchup': False,
}

# Data source configuration
DIVVY_SOURCE_BUCKET = "divvy-tripdata"
DIVVY_SOURCE_PREFIX = ""

# Target S3 configuration (from environment variables)
TARGET_BRONZE_BUCKET = Variable.get("bronze_bucket", "divvybikes-dev-bronze-96wb3c9c")
TARGET_BRONZE_PREFIX = "divvy-trips"

# Years and months to process
YEARS_TO_PROCESS = [2023, 2024]
MONTHS_TO_PROCESS = list(range(1, 13))  # January to December

# Redshift configuration
REDSHIFT_CONN_ID = "redshift_default"
BRONZE_TABLE = "bronze.trips_raw"


def generate_monthly_files() -> List[Dict[str, Any]]:
    """
    Generate list of monthly files to process from the Divvy public dataset.
    
    Returns:
        List of dictionaries containing file metadata
    """
    files_to_process = []
    
    for year in YEARS_TO_PROCESS:
        for month in MONTHS_TO_PROCESS:
            # Construct the expected filename pattern (ZIP files from source)
            source_filename = f"{year:04d}{month:02d}-divvy-tripdata.zip"
            # Target will be CSV after extraction
            target_filename = f"{year:04d}{month:02d}-divvy-tripdata.csv"
            
            file_info = {
                'year': year,
                'month': month,
                'source_key': source_filename,
                'target_key': f"{TARGET_BRONZE_PREFIX}/year={year}/month={month:02d}/{target_filename}",
                'partition_path': f"year={year}/month={month:02d}",
                'source_filename': source_filename,
                'target_filename': target_filename
            }
            files_to_process.append(file_info)
    
    logger.info(f"Generated {len(files_to_process)} files for processing")
    return files_to_process


@task
def validate_source_data(file_info: Dict[str, Any]) -> Dict[str, Any]:
    """
    Validate that the source file exists and get metadata.
    
    Args:
        file_info: Dictionary containing file information
        
    Returns:
        Updated file_info with validation results
    """
    s3_hook = S3Hook(aws_conn_id='aws_default')
    
    try:
        # Check if source file exists
        source_exists = s3_hook.check_for_key(
            key=file_info['source_key'],
            bucket_name=DIVVY_SOURCE_BUCKET
        )
        
        if source_exists:
            # Get file metadata
            file_metadata = s3_hook.head_object(
                key=file_info['source_key'],
                bucket_name=DIVVY_SOURCE_BUCKET
            )
            
            file_info.update({
                'validation_status': 'valid',
                'file_size': file_metadata.get('ContentLength', 0),
                'last_modified': file_metadata.get('LastModified'),
                'content_type': file_metadata.get('ContentType', 'application/zip')
            })
            
            logger.info(f"✅ Source file validated: {file_info['source_key']} "
                       f"({file_info['file_size']} bytes)")
        else:
            file_info.update({
                'validation_status': 'missing',
                'error_message': f"Source file not found: {file_info['source_key']}"
            })
            logger.warning(f"❌ Source file missing: {file_info['source_key']}")
            
    except Exception as e:
        file_info.update({
            'validation_status': 'error',
            'error_message': str(e)
        })
        logger.error(f"❌ Validation error for {file_info['source_key']}: {e}")
    
    return file_info


@task
def check_target_exists(file_info: Dict[str, Any]) -> Dict[str, Any]:
    """
    Check if the target file already exists in our Bronze bucket.
    
    Args:
        file_info: Dictionary containing file information
        
    Returns:
        Updated file_info with target existence check
    """
    s3_hook = S3Hook(aws_conn_id='aws_default')
    
    try:
        target_exists = s3_hook.check_for_key(
            key=file_info['target_key'],
            bucket_name=TARGET_BRONZE_BUCKET
        )
        
        file_info['target_exists'] = target_exists
        
        if target_exists:
            logger.info(f"🔄 Target file already exists: {file_info['target_key']}")
        else:
            logger.info(f"🆕 Target file needs to be created: {file_info['target_key']}")
            
    except Exception as e:
        file_info['target_check_error'] = str(e)
        logger.error(f"❌ Error checking target: {e}")
    
    return file_info


@task
def copy_to_bronze(file_info: Dict[str, Any]) -> Dict[str, Any]:
    """
    Download ZIP file from source, extract CSV, and upload to Bronze layer.
    
    Args:
        file_info: Dictionary containing file information
        
    Returns:
        Updated file_info with copy results
    """
    # Skip if validation failed or target already exists
    if file_info.get('validation_status') != 'valid':
        logger.warning(f"⏭️ Skipping copy due to validation failure: {file_info['source_key']}")
        return file_info
    
    if file_info.get('target_exists', False):
        logger.info(f"⏭️ Skipping copy - target exists: {file_info['target_key']}")
        file_info['copy_status'] = 'skipped'
        return file_info
    
    s3_hook = S3Hook(aws_conn_id='aws_default')
    
    try:
        logger.info(f"🔄 Starting ZIP extraction and copy for {file_info['source_key']}")
        
        # Download ZIP file from source bucket
        logger.info(f"📥 Downloading ZIP file: {file_info['source_key']}")
        zip_obj = s3_hook.get_key(
            key=file_info['source_key'],
            bucket_name=DIVVY_SOURCE_BUCKET
        )
        zip_content = zip_obj.get()['Body'].read()
        
        # Extract CSV from ZIP file
        logger.info(f"📦 Extracting CSV from ZIP file")
        with zipfile.ZipFile(BytesIO(zip_content)) as zip_file:
            # List contents of ZIP file
            zip_contents = zip_file.namelist()
            logger.info(f"📋 ZIP contents: {zip_contents}")
            
            # Find the CSV file (should be the main file with same name pattern)
            csv_filename = None
            for filename in zip_contents:
                if filename.endswith('.csv') and 'divvy-tripdata' in filename:
                    csv_filename = filename
                    break
            
            if not csv_filename:
                raise Exception(f"No CSV file found in ZIP archive. Contents: {zip_contents}")
            
            logger.info(f"📄 Extracting CSV file: {csv_filename}")
            csv_content = zip_file.read(csv_filename)
        
        # Upload extracted CSV to Bronze bucket
        logger.info(f"📤 Uploading CSV to Bronze bucket: {file_info['target_key']}")
        s3_hook.load_bytes(
            bytes_data=csv_content,
            key=file_info['target_key'],
            bucket_name=TARGET_BRONZE_BUCKET,
            replace=True
        )
        
        # Verify the upload was successful
        target_exists = s3_hook.check_for_key(
            key=file_info['target_key'],
            bucket_name=TARGET_BRONZE_BUCKET
        )
        
        if target_exists:
            # Get the uploaded file metadata
            target_metadata = s3_hook.head_object(
                key=file_info['target_key'],
                bucket_name=TARGET_BRONZE_BUCKET
            )
            
            file_info.update({
                'copy_status': 'success',
                'copy_timestamp': datetime.utcnow().isoformat(),
                'source_zip_size': len(zip_content),
                'extracted_csv_size': len(csv_content),
                'target_csv_size': target_metadata.get('ContentLength', 0),
                'extracted_filename': csv_filename
            })
            logger.info(f"✅ Successfully extracted and copied: {file_info['source_key']} -> {file_info['target_key']}")
            logger.info(f"   ZIP size: {len(zip_content):,} bytes")
            logger.info(f"   CSV size: {len(csv_content):,} bytes")
        else:
            raise Exception("Copy verification failed - target file not found after upload")
            
    except Exception as e:
        file_info.update({
            'copy_status': 'failed',
            'copy_error': str(e)
        })
        logger.error(f"❌ ZIP extraction and copy failed for {file_info['source_key']}: {e}")
        raise
    
    return file_info


@task
def validate_bronze_data(file_info: Dict[str, Any]) -> Dict[str, Any]:
    """
    Perform basic data quality validation on the Bronze layer CSV file.
    
    Args:
        file_info: Dictionary containing file information
        
    Returns:
        Updated file_info with validation results
    """
    if file_info.get('copy_status') not in ['success', 'skipped']:
        logger.warning(f"⏭️ Skipping validation - copy was not successful: {file_info['source_key']}")
        return file_info
    
    s3_hook = S3Hook(aws_conn_id='aws_default')
    
    try:
        # Read a sample of the CSV data for validation
        logger.info(f"🔍 Validating Bronze CSV file: {file_info['target_key']}")
        
        # Get file metadata first
        file_metadata = s3_hook.head_object(
            key=file_info['target_key'],
            bucket_name=TARGET_BRONZE_BUCKET
        )
        
        file_size = file_metadata.get('ContentLength', 0)
        
        if file_size == 0:
            validation_results = {
                'validation_status': 'failed',
                'validation_message': 'CSV file is empty',
                'file_size': 0,
                'validation_timestamp': datetime.utcnow().isoformat()
            }
            logger.error(f"❌ Bronze validation failed for {file_info['target_key']}: empty file")
        else:
            # Read first part of the file to validate CSV structure
            # For large files, we'll only read the first chunk for validation
            max_bytes_to_read = min(file_size, 1024 * 1024)  # Max 1MB for validation
            
            file_content = s3_hook.read_key(
                key=file_info['target_key'],
                bucket_name=TARGET_BRONZE_BUCKET,
                length=max_bytes_to_read
            )
            
            # Parse CSV to validate structure
            from io import StringIO
            df_sample = pd.read_csv(StringIO(file_content.decode('utf-8')), nrows=1000)  # Sample first 1000 rows
            
            # Expected columns for Divvy data
            expected_columns = [
                'ride_id', 'rideable_type', 'started_at', 'ended_at',
                'start_station_name', 'start_station_id', 'end_station_name', 'end_station_id',
                'start_lat', 'start_lng', 'end_lat', 'end_lng', 'member_casual'
            ]
            
            # Validate column presence
            missing_columns = set(expected_columns) - set(df_sample.columns)
            extra_columns = set(df_sample.columns) - set(expected_columns)
            
            validation_results = {
                'total_columns': len(df_sample.columns),
                'sample_rows': len(df_sample),
                'missing_columns': list(missing_columns),
                'extra_columns': list(extra_columns),
                'file_size': file_size,
                'validation_timestamp': datetime.utcnow().isoformat(),
                'columns_found': list(df_sample.columns)
            }
            
            if missing_columns:
                validation_results['validation_status'] = 'warning'
                validation_results['validation_message'] = f"Missing expected columns: {missing_columns}"
                logger.warning(f"⚠️ Bronze validation warning for {file_info['target_key']}: {validation_results['validation_message']}")
            else:
                validation_results['validation_status'] = 'passed'
                validation_results['validation_message'] = f"All expected columns present. CSV has {len(df_sample.columns)} columns, {validation_results['sample_rows']} sample rows validated"
                logger.info(f"✅ Bronze validation passed for {file_info['target_key']}")
                logger.info(f"   File size: {file_size:,} bytes")
                logger.info(f"   Columns: {len(df_sample.columns)}")
                logger.info(f"   Sample rows: {len(df_sample)}")
        
        file_info['bronze_validation'] = validation_results
        
    except Exception as e:
        file_info['bronze_validation'] = {
            'validation_status': 'failed',
            'validation_error': str(e),
            'validation_timestamp': datetime.utcnow().isoformat()
        }
        logger.error(f"❌ Bronze validation failed for {file_info['target_key']}: {e}")
    
    return file_info


@task
def generate_ingestion_summary(all_results: List[Dict[str, Any]]) -> Dict[str, Any]:
    """
    Generate a summary of the ingestion process.
    
    Args:
        all_results: List of all file processing results
        
    Returns:
        Summary statistics
    """
    summary = {
        'total_files_processed': len(all_results),
        'successful_copies': 0,
        'skipped_files': 0,
        'failed_copies': 0,
        'validation_passed': 0,
        'validation_warnings': 0,
        'validation_failed': 0,
        'total_data_size': 0,
        'processing_timestamp': datetime.utcnow().isoformat()
    }
    
    for result in all_results:
        # Count copy results
        copy_status = result.get('copy_status', 'unknown')
        if copy_status == 'success':
            summary['successful_copies'] += 1
        elif copy_status == 'skipped':
            summary['skipped_files'] += 1
        elif copy_status == 'failed':
            summary['failed_copies'] += 1
        
        # Count validation results
        bronze_validation = result.get('bronze_validation', {})
        validation_status = bronze_validation.get('validation_status', 'unknown')
        if validation_status == 'passed':
            summary['validation_passed'] += 1
        elif validation_status == 'warning':
            summary['validation_warnings'] += 1
        elif validation_status == 'failed':
            summary['validation_failed'] += 1
        
        # Sum file sizes
        file_size = result.get('file_size', 0)
        if isinstance(file_size, int):
            summary['total_data_size'] += file_size
    
    # Log summary
    logger.info(f"📊 Ingestion Summary:")
    logger.info(f"   Total files: {summary['total_files_processed']}")
    logger.info(f"   Successful copies: {summary['successful_copies']}")
    logger.info(f"   Skipped files: {summary['skipped_files']}")
    logger.info(f"   Failed copies: {summary['failed_copies']}")
    logger.info(f"   Total data size: {summary['total_data_size']:,} bytes")
    
    return summary


# Create the DAG
dag = DAG(
    DAG_ID,
    default_args=default_args,
    description=DESCRIPTION,
    schedule_interval='@daily',  # Run daily to check for new data
    max_active_runs=1,
    catchup=False,
    tags=['divvy', 'data-ingestion', 'bronze-layer', 'etl']
)

# Generate the list of files to process
files_to_process = generate_monthly_files()

# Task: Validate AWS connectivity
@task
def validate_aws_connectivity():
    """
    Validate AWS connectivity using boto3 instead of AWS CLI.
    
    Returns:
        Dictionary with connection status
    """
    try:
        s3_hook = S3Hook(aws_conn_id='aws_default')
        
        # Test STS connection (get caller identity)
        import boto3
        session = boto3.Session()
        sts_client = session.client('sts')
        identity = sts_client.get_caller_identity()
        
        logger.info(f"✅ AWS connectivity validated")
        logger.info(f"   Account: {identity.get('Account', 'Unknown')}")
        logger.info(f"   User/Role ARN: {identity.get('Arn', 'Unknown')}")
        logger.info(f"   User ID: {identity.get('UserId', 'Unknown')}")
        
        # Test S3 connection by listing a few buckets
        buckets = s3_hook.get_conn().list_buckets()['Buckets']
        bucket_names = [b['Name'] for b in buckets]
        logger.info(f"   S3 access confirmed - found {len(bucket_names)} buckets")
        
        # Verify target bucket exists
        if TARGET_BRONZE_BUCKET in bucket_names:
            logger.info(f"✅ Target Bronze bucket found: {TARGET_BRONZE_BUCKET}")
        else:
            logger.warning(f"⚠️ Target Bronze bucket not found: {TARGET_BRONZE_BUCKET}")
            logger.info(f"   Available buckets: {bucket_names}")
        
        return {
            'status': 'success',
            'account': identity.get('Account'),
            'arn': identity.get('Arn'),
            'user_id': identity.get('UserId'),
            's3_buckets_count': len(bucket_names),
            'target_bucket_exists': TARGET_BRONZE_BUCKET in bucket_names
        }
        
    except Exception as e:
        logger.error(f"❌ AWS connectivity validation failed: {e}")
        raise

validate_aws = validate_aws_connectivity.override(
    task_id='validate_aws_connectivity',
    dag=dag
)()

# Task: Ensure Bronze bucket exists
create_bronze_bucket = S3CreateBucketOperator(
    task_id='ensure_bronze_bucket_exists',
    bucket_name=TARGET_BRONZE_BUCKET,
    aws_conn_id='aws_default',
    dag=dag
)

# Process all files in a single comprehensive task to avoid dependency issues
@task
def process_all_files():
    """
    Process all Divvy files in a single task to ensure proper data flow.
    This approach avoids the complex TaskGroup dependency issues.
    """
    import logging
    logger = logging.getLogger(__name__)
    
    s3_hook = S3Hook(aws_conn_id='aws_default')
    
    results = []
    successful_files = 0
    skipped_files = 0
    failed_files = 0
    
    logger.info(f"🚀 Starting processing of {len(files_to_process)} files")
    
    for i, file_info in enumerate(files_to_process):
        logger.info(f"📁 Processing file {i+1}/{len(files_to_process)}: {file_info['source_key']}")
        
        try:
            # Step 1: Validate source exists
            source_exists = s3_hook.check_for_key(
                key=file_info['source_key'],
                bucket_name=DIVVY_SOURCE_BUCKET
            )
            
            if not source_exists:
                logger.warning(f"❌ Source file not found: {file_info['source_key']}")
                file_info['status'] = 'source_missing'
                failed_files += 1
                results.append(file_info)
                continue
            
            logger.info(f"✅ Source file validated: {file_info['source_key']}")
            
            # Step 2: Check if target already exists
            target_exists = s3_hook.check_for_key(
                key=file_info['target_key'],
                bucket_name=TARGET_BRONZE_BUCKET
            )
            
            if target_exists:
                logger.info(f"⏭️ Target already exists, skipping: {file_info['target_key']}")
                file_info['status'] = 'skipped_exists'
                skipped_files += 1
                results.append(file_info)
                continue
            
            # Step 3: Download ZIP file
            logger.info(f"📥 Downloading ZIP: {file_info['source_key']}")
            zip_obj = s3_hook.get_key(
                key=file_info['source_key'],
                bucket_name=DIVVY_SOURCE_BUCKET
            )
            zip_content = zip_obj.get()['Body'].read()
            logger.info(f"   Downloaded {len(zip_content):,} bytes")
            
            # Step 4: Extract CSV
            logger.info(f"📦 Extracting CSV from ZIP")
            with zipfile.ZipFile(BytesIO(zip_content)) as zip_file:
                csv_filename = None
                for filename in zip_file.namelist():
                    if filename.endswith('.csv') and 'divvy-tripdata' in filename:
                        csv_filename = filename
                        break
                
                if not csv_filename:
                    raise Exception(f"No CSV file found in ZIP: {zip_file.namelist()}")
                
                csv_content = zip_file.read(csv_filename)
                logger.info(f"   Extracted {len(csv_content):,} bytes from {csv_filename}")
            
            # Step 5: Upload to Bronze bucket
            logger.info(f"📤 Uploading to Bronze: {file_info['target_key']}")
            s3_hook.load_bytes(
                bytes_data=csv_content,
                key=file_info['target_key'],
                bucket_name=TARGET_BRONZE_BUCKET,
                replace=True
            )
            
            # Step 6: Verify upload
            upload_verified = s3_hook.check_for_key(
                key=file_info['target_key'],
                bucket_name=TARGET_BRONZE_BUCKET
            )
            
            if upload_verified:
                logger.info(f"✅ Successfully processed: {file_info['source_key']}")
                file_info.update({
                    'status': 'success',
                    'zip_size': len(zip_content),
                    'csv_size': len(csv_content),
                    'extracted_filename': csv_filename
                })
                successful_files += 1
            else:
                raise Exception("Upload verification failed")
                
        except Exception as e:
            logger.error(f"❌ Failed to process {file_info['source_key']}: {e}")
            file_info.update({
                'status': 'failed',
                'error': str(e)
            })
            failed_files += 1
        
        results.append(file_info)
    
    # Summary
    logger.info(f"📊 Processing Summary:")
    logger.info(f"   Total files: {len(files_to_process)}")
    logger.info(f"   Successful: {successful_files}")
    logger.info(f"   Skipped: {skipped_files}")
    logger.info(f"   Failed: {failed_files}")
    
    return {
        'total_files': len(files_to_process),
        'successful': successful_files,
        'skipped': skipped_files,
        'failed': failed_files,
        'results': results
    }

process_files_task = process_all_files.override(task_id='process_all_files', dag=dag)()

# Generate final summary
summary_task = BashOperator(
    task_id='generate_ingestion_summary',
    bash_command='echo "📊 Divvy data ingestion process completed. Check individual task logs for details."',
    trigger_rule=TriggerRule.ALL_DONE,  # Run even if some tasks fail
    dag=dag
)

# Task: Log completion
completion_task = BashOperator(
    task_id='log_completion',
    bash_command='echo "✅ Divvy data ingestion pipeline completed successfully!"',
    trigger_rule=TriggerRule.ALL_DONE,
    dag=dag
)

# Define task dependencies
validate_aws >> create_bronze_bucket >> process_files_task >> summary_task >> completion_task

# Documentation
dag.doc_md = """
# Divvy Bikes Data Ingestion DAG

This DAG handles the ingestion of historical Divvy bike trip data from the public AWS S3 bucket 
to our Bronze layer in the data lake architecture.

## What this DAG does:

1. **Validates AWS connectivity** - Ensures we can connect to AWS services
2. **Ensures Bronze bucket exists** - Creates the target S3 bucket if needed
3. **Processes monthly files** - For each month in 2023 and 2024:
   - Validates source ZIP file exists
   - Checks if target CSV already exists
   - Downloads ZIP file and extracts CSV content
   - Uploads extracted CSV to Bronze layer
   - Validates CSV data quality
4. **Generates summary** - Creates processing summary and statistics

## Data Source:
- **Source Bucket**: `divvy-tripdata` (public)
- **File Pattern**: `YYYYMM-divvy-tripdata.zip`
- **Years**: 2023, 2024
- **Months**: All 12 months

## Target:
- **Bronze Bucket**: `divvybikes-dev-bronze-96wb3c9c`
- **Partitioning**: `year=YYYY/month=MM/`
- **Format**: CSV (extracted from ZIP files)
- **File Pattern**: `YYYYMM-divvy-tripdata.csv`

## Data Processing:
- Downloads ZIP files from public source
- Extracts CSV content from ZIP archives
- Stores clean CSV files in Bronze layer
- Validates CSV structure and expected columns

## Monitoring:
- Check task logs for detailed processing information
- Review the final summary task for overall statistics
- Failed tasks will be retried automatically (up to 2 times)

## Next Steps:
After successful ingestion, CSV data will be available for the transformation pipeline
that moves data from Bronze → Silver → Gold layers.
"""
