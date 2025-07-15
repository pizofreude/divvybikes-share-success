#!/usr/bin/env python3
"""
Setup Airflow Connections Script
This script configures the necessary connections in Airflow for the Divvy project.
"""

import os
import logging
from dotenv import load_dotenv
from airflow.models import Connection
from airflow.utils.db import provide_session

# Load environment variables from .env file
load_dotenv()

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@provide_session
def create_connection(session, conn_id, conn_type, host=None, port=None, 
                     schema=None, login=None, password=None, extra=None):
    """
    Create or update an Airflow connection.
    """
    # Check if connection already exists
    existing_conn = session.query(Connection).filter(Connection.conn_id == conn_id).first()
    
    if existing_conn:
        logger.info(f"Updating existing connection: {conn_id}")
        existing_conn.conn_type = conn_type
        existing_conn.host = host
        existing_conn.port = port
        existing_conn.schema = schema
        existing_conn.login = login
        existing_conn.password = password
        existing_conn.extra = extra
    else:
        logger.info(f"Creating new connection: {conn_id}")
        new_conn = Connection(
            conn_id=conn_id,
            conn_type=conn_type,
            host=host,
            port=port,
            schema=schema,
            login=login,
            password=password,
            extra=extra
        )
        session.add(new_conn)
    
    session.commit()
    logger.info(f"✅ Connection '{conn_id}' configured successfully")

def setup_aws_connection():
    """Setup AWS connection for S3 and other AWS services."""
    aws_region = os.getenv('AWS_REGION', 'ap-southeast-2')
    create_connection(
        conn_id='aws_default',
        conn_type='aws',
        extra=f'{{"region_name": "{aws_region}"}}'
    )

def setup_redshift_connection():
    """Setup Redshift connection for data warehouse operations."""
    # Get connection details from environment variables
    redshift_host = os.getenv('REDSHIFT_ENDPOINT')
    redshift_port = int(os.getenv('REDSHIFT_PORT', 5439))
    redshift_database = os.getenv('REDSHIFT_DATABASE_NAME', 'divvy')
    redshift_username = os.getenv('REDSHIFT_ADMIN_USERNAME', 'admin')
    redshift_password = os.getenv('REDSHIFT_ADMIN_PASSWORD')
    redshift_workgroup = os.getenv('REDSHIFT_WORKGROUP', 'divvybikes-dev')
    redshift_namespace = os.getenv('REDSHIFT_NAMESPACE', 'divvybikes-dev')
    
    if not redshift_host or not redshift_password:
        raise ValueError("REDSHIFT_ENDPOINT and REDSHIFT_ADMIN_PASSWORD must be set in environment variables")
    
    create_connection(
        conn_id='redshift_default',
        conn_type='redshift',
        host=redshift_host,
        port=redshift_port,
        schema=redshift_database,
        login=redshift_username,
        password=redshift_password,
        extra=f'{{"workgroup": "{redshift_workgroup}", "namespace": "{redshift_namespace}"}}'
    )

def setup_postgres_connection():
    """Setup PostgreSQL connection for Airflow metadata."""
    create_connection(
        conn_id='postgres_default',
        conn_type='postgres',
        host='postgres',
        port=5432,
        schema='airflow',
        login='airflow',
        password='airflow'
    )

def main():
    """Main function to set up all connections."""
    logger.info("🔧 Setting up Airflow connections for Divvy project...")
    
    try:
        setup_aws_connection()
        setup_redshift_connection()
        setup_postgres_connection()
        
        logger.info("✅ All connections configured successfully!")
        
    except Exception as e:
        logger.error(f"❌ Error setting up connections: {e}")
        raise

if __name__ == "__main__":
    main()
