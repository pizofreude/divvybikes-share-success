"""
Test DAG for Divvy Bikes Project

This is a simple test DAG to verify that Airflow is properly configured
and can connect to AWS services and Redshift.

Author: pizofreude
Created: 2025-07-15
"""

from datetime import datetime, timedelta
import logging

from airflow import DAG
from airflow.decorators import task
from airflow.providers.amazon.aws.hooks.s3 import S3Hook
from airflow.providers.postgres.hooks.postgres import PostgresHook
from airflow.operators.bash import BashOperator
from airflow.models import Variable

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Default arguments
default_args = {
    'owner': 'pizofreude',
    'depends_on_past': False,
    'start_date': datetime(2025, 7, 15),
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=2),
}

# Create the DAG
dag = DAG(
    'test_divvy_connections',
    default_args=default_args,
    description='Test DAG to verify Airflow connections for Divvy project',
    schedule_interval=None,  # Manual trigger only
    catchup=False,
    tags=['test', 'connectivity', 'divvy']
)

@task
def test_aws_connection():
    """Test AWS S3 connection and list available buckets."""
    try:
        s3_hook = S3Hook(aws_conn_id='aws_default')
        
        # List buckets to verify connection using get_conn()
        s3_client = s3_hook.get_conn()
        response = s3_client.list_buckets()
        buckets = response['Buckets']
        
        logger.info(f"✅ AWS S3 connection successful!")
        logger.info(f"📦 Found {len(buckets)} buckets in account")
        
        # Check if our target buckets exist
        target_buckets = [
            'divvybikes-dev-bronze-96wb3c9c',
            'divvybikes-dev-silver-96wb3c9c',
            'divvybikes-dev-gold-96wb3c9c'
        ]
        
        bucket_names = [bucket['Name'] for bucket in buckets]
        
        for target_bucket in target_buckets:
            if target_bucket in bucket_names:
                logger.info(f"✅ Target bucket found: {target_bucket}")
            else:
                logger.warning(f"⚠️ Target bucket not found: {target_bucket}")
        
        return {"status": "success", "bucket_count": len(buckets)}
        
    except Exception as e:
        logger.error(f"❌ AWS S3 connection failed: {e}")
        raise

@task  
def test_redshift_connection():
    """Test Redshift connection and run a simple query."""
    try:
        # Use PostgresHook since Redshift is PostgreSQL-compatible
        redshift_hook = PostgresHook(postgres_conn_id='redshift_default')
        
        # Test connection with a simple query
        result = redshift_hook.get_first("SELECT version()")
        
        logger.info(f"✅ Redshift connection successful!")
        logger.info(f"📊 Database version: {result[0] if result else 'Unknown'}")
        
        # Test our schemas exist
        schemas_query = """
        SELECT schema_name 
        FROM information_schema.schemata 
        WHERE schema_name IN ('bronze', 'silver', 'gold', 'staging')
        ORDER BY schema_name
        """
        
        schemas = redshift_hook.get_records(schemas_query)
        schema_names = [schema[0] for schema in schemas] if schemas else []
        
        logger.info(f"📋 Found schemas: {schema_names}")
        
        expected_schemas = ['bronze', 'silver', 'gold', 'staging']
        for schema in expected_schemas:
            if schema in schema_names:
                logger.info(f"✅ Schema found: {schema}")
            else:
                logger.warning(f"⚠️ Schema not found: {schema}")
        
        return {"status": "success", "schemas": schema_names}
        
    except Exception as e:
        logger.error(f"❌ Redshift connection failed: {e}")
        raise

@task
def test_variables():
    """Test that required Airflow variables are configured."""
    try:
        required_variables = [
            'bronze_bucket',
            'silver_bucket', 
            'gold_bucket',
            'divvy_source_bucket'
        ]
        
        variables_status = {}
        
        for var_name in required_variables:
            try:
                var_value = Variable.get(var_name)
                variables_status[var_name] = {"status": "found", "value": var_value}
                logger.info(f"✅ Variable '{var_name}': {var_value}")
            except Exception as e:
                variables_status[var_name] = {"status": "missing", "error": str(e)}
                logger.warning(f"⚠️ Variable '{var_name}' not found: {e}")
        
        return variables_status
        
    except Exception as e:
        logger.error(f"❌ Variable check failed: {e}")
        raise

@task
def test_source_data_access():
    """Test access to the public Divvy data source."""
    try:
        s3_hook = S3Hook(aws_conn_id='aws_default')
        
        # Test access to public Divvy bucket
        source_bucket = 'divvy-tripdata'
        
        # List first few files to verify access
        keys = s3_hook.list_keys(bucket_name=source_bucket, max_items=5)
        
        if keys:
            logger.info(f"✅ Access to source data successful!")
            logger.info(f"📁 Found {len(keys)} sample files:")
            for key in keys[:3]:  # Show first 3 files
                logger.info(f"   - {key}")
        else:
            logger.warning("⚠️ No files found in source bucket")
        
        # Check for specific test file
        test_file = "202401-divvy-tripdata.csv"
        file_exists = s3_hook.check_for_key(key=test_file, bucket_name=source_bucket)
        
        if file_exists:
            logger.info(f"✅ Test file found: {test_file}")
        else:
            logger.warning(f"⚠️ Test file not found: {test_file}")
        
        return {"status": "success", "sample_files": keys[:5]}
        
    except Exception as e:
        logger.error(f"❌ Source data access failed: {e}")
        raise

@task
def generate_test_summary(aws_result, redshift_result, variables_result, source_result):
    """Generate a summary of all connectivity tests."""
    
    summary = {
        "test_timestamp": datetime.utcnow().isoformat(),
        "aws_s3": aws_result.get("status", "failed"),
        "redshift": redshift_result.get("status", "failed"),
        "variables": "success" if all(v.get("status") == "found" for v in variables_result.values()) else "partial",
        "source_data": source_result.get("status", "failed")
    }
    
    logger.info("📊 CONNECTIVITY TEST SUMMARY")
    logger.info("="*50)
    logger.info(f"AWS S3 Connection: {summary['aws_s3'].upper()}")
    logger.info(f"Redshift Connection: {summary['redshift'].upper()}")
    logger.info(f"Airflow Variables: {summary['variables'].upper()}")
    logger.info(f"Source Data Access: {summary['source_data'].upper()}")
    logger.info("="*50)
    
    all_passed = all(status == "success" for status in [
        summary['aws_s3'], summary['redshift'], summary['source_data']
    ])
    
    if all_passed and summary['variables'] in ['success', 'partial']:
        logger.info("🎉 All connectivity tests PASSED! Ready for data ingestion.")
    else:
        logger.warning("⚠️ Some tests failed. Please check the logs and fix configuration.")
    
    return summary

# Define tasks
test_system = BashOperator(
    task_id='test_system_info',
    bash_command='echo "🔍 Testing Airflow connectivity for Divvy project..." && python --version && echo "✅ Python available"',
    dag=dag
)

# Task instances (with DAG context)
with dag:
    aws_test = test_aws_connection.override(task_id='test_aws_s3')()
    redshift_test = test_redshift_connection.override(task_id='test_redshift')()
    variables_test = test_variables.override(task_id='test_variables')()
    source_test = test_source_data_access.override(task_id='test_source_data')()

    summary = generate_test_summary.override(task_id='generate_summary')(
        aws_test, redshift_test, variables_test, source_test
    )

completion = BashOperator(
    task_id='test_completion',
    bash_command='echo "✅ Connectivity tests completed! Check the logs for results."',
    dag=dag
)

# Define dependencies
test_system >> [aws_test, redshift_test, variables_test, source_test] >> summary >> completion

# Documentation
dag.doc_md = """
# Connectivity Test DAG

This DAG tests all the connections and configurations needed for the Divvy Bikes data pipeline.

## Tests Performed:

1. **AWS S3 Connection** - Verifies connection to AWS and lists available buckets
2. **Redshift Connection** - Tests connection to Redshift Serverless and checks schemas  
3. **Airflow Variables** - Confirms all required variables are configured
4. **Source Data Access** - Tests access to the public Divvy data bucket

## How to Use:

1. Enable this DAG in the Airflow UI
2. Trigger manually using the "Trigger DAG" button
3. Monitor the execution in Graph or Tree view
4. Check task logs for detailed results
5. Review the summary task for overall status

## Expected Results:

- All tasks should complete successfully (green)
- Check logs for detailed connectivity information
- Any warnings should be investigated before running the main ingestion DAG

This test should be run before executing the main `divvy_data_ingestion` DAG.
"""
