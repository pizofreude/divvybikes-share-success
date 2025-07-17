#!/usr/bin/env python3
"""
Setup Airflow Variables Script
This script configures the necessary variables in Airflow for the Divvy project.
"""

import logging
from airflow.models import Variable
from airflow.utils.db import provide_session

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@provide_session
def set_variable(session, key, value, description=None):
    """
    Create or update an Airflow variable.
    """
    try:
        # Check if variable already exists
        existing_var = session.query(Variable).filter(Variable.key == key).first()
        
        if existing_var:
            logger.info(f"Updating existing variable: {key}")
            existing_var.val = value
        else:
            logger.info(f"Creating new variable: {key}")
            new_var = Variable(key=key, val=value)
            session.add(new_var)
        
        session.commit()
        logger.info(f"✅ Variable '{key}' configured successfully")
        
    except Exception as e:
        logger.error(f"❌ Error setting variable '{key}': {e}")
        raise

def setup_s3_variables():
    """Setup S3 bucket variables from Terraform outputs."""
    
    # S3 bucket names (from Terraform outputs)
    set_variable(
        key='bronze_bucket',
        value='divvybikes-dev-bronze-96wb3c9c',
        description='S3 bucket for Bronze layer (raw data)'
    )
    
    set_variable(
        key='silver_bucket',
        value='divvybikes-dev-silver-96wb3c9c',
        description='S3 bucket for Silver layer (cleaned data)'
    )
    
    set_variable(
        key='gold_bucket',
        value='divvybikes-dev-gold-96wb3c9c',
        description='S3 bucket for Gold layer (analytics-ready data)'
    )

def setup_redshift_variables():
    """Setup Redshift configuration variables."""
    
    set_variable(
        key='redshift_endpoint',
        value='divvybikes-dev.864899839546.ap-southeast-2.redshift-serverless.amazonaws.com',
        description='Redshift Serverless endpoint'
    )
    
    set_variable(
        key='redshift_database',
        value='divvy',
        description='Redshift database name'
    )
    
    set_variable(
        key='redshift_workgroup',
        value='divvybikes-dev',
        description='Redshift Serverless workgroup'
    )
    
    set_variable(
        key='redshift_namespace',
        value='divvybikes-dev',
        description='Redshift Serverless namespace'
    )

def setup_data_source_variables():
    """Setup data source configuration variables."""
    
    set_variable(
        key='divvy_source_bucket',
        value='divvy-tripdata',
        description='Public S3 bucket containing Divvy source data'
    )
    
    set_variable(
        key='data_years_to_process',
        value='2023,2024',
        description='Comma-separated list of years to process'
    )
    
    set_variable(
        key='bronze_prefix',
        value='divvy-trips',
        description='S3 prefix for Bronze layer data'
    )

def setup_pipeline_variables():
    """Setup data pipeline configuration variables."""
    
    set_variable(
        key='max_parallel_tasks',
        value='5',
        description='Maximum number of parallel tasks for data processing'
    )
    
    set_variable(
        key='data_retention_days',
        value='2555',  # 7 years
        description='Data retention period in days'
    )
    
    set_variable(
        key='enable_data_quality_checks',
        value='true',
        description='Enable data quality validation checks'
    )

def setup_notification_variables():
    """Setup notification configuration variables."""
    
    set_variable(
        key='notification_email',
        value='pizofreude@proton.me',
        description='Email address for pipeline notifications'
    )
    
    set_variable(
        key='slack_webhook_url',
        value='',  # Add your Slack webhook URL if needed
        description='Slack webhook URL for notifications'
    )

def main():
    """Main function to set up all variables."""
    logger.info("🔧 Setting up Airflow variables for Divvy project...")
    
    try:
        setup_s3_variables()
        setup_redshift_variables()
        setup_data_source_variables()
        setup_pipeline_variables()
        setup_notification_variables()
        
        logger.info("✅ All variables configured successfully!")
        
        # Print summary
        logger.info("\n📋 Variable Summary:")
        logger.info("   S3 Buckets: bronze, silver, gold configured")
        logger.info("   Redshift: endpoint, database, workgroup, namespace configured")
        logger.info("   Data Sources: divvy source bucket and processing years configured")
        logger.info("   Pipeline: max parallel tasks, retention, quality checks configured")
        logger.info("   Notifications: email configured (Slack optional)")
        
    except Exception as e:
        logger.error(f"❌ Error setting up variables: {e}")
        raise

if __name__ == "__main__":
    main()
