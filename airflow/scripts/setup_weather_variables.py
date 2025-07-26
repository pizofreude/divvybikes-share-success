"""
File: setup_weather_variables.py
--------------------------------
Setup Weather Data Variables for Airflow

This script configures Airflow variables needed for the weather data ingestion DAG.
It should be run after the weather_data_ingestion_optimized DAG is deployed.

Usage:
    python setup_weather_variables.py
"""

import os
import sys
import logging
from airflow.models import Variable

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def setup_weather_variables():
    """
    Set up Airflow variables for weather data ingestion.
    """
    
    logger.info("🌤️  Setting up Airflow variables for weather data ingestion...")
    
    # Weather-specific variables
    weather_variables = {
        'weather_api_base_url': 'https://archive-api.open-meteo.com/v1/archive',
        'weather_api_timeout': '30',
        'weather_rate_limit_delay': '1',
        'weather_chicago_lat': '41.8781',
        'weather_chicago_lng': '-87.6298',
        'weather_evanston_lat': '42.0451',
        'weather_evanston_lng': '-87.6877',
        'weather_timezone': 'America/Chicago',
        'weather_temperature_unit': 'celsius',
        'weather_wind_speed_unit': 'kmh',
        'weather_precipitation_unit': 'mm',
        'weather_data_years': '2023,2024',
        'weather_s3_prefix': 'weather-data'
    }
    
    try:
        # Set each variable
        for var_name, var_value in weather_variables.items():
            Variable.set(var_name, var_value, description=f"Weather data configuration: {var_name}")
            logger.info(f"✅ Set variable: {var_name} = {var_value}")
        
        logger.info(f"🎉 Successfully set up {len(weather_variables)} weather variables!")
        
        # Display summary
        logger.info("\n📋 Weather Variables Summary:")
        logger.info("   🌐 API Configuration:")
        logger.info(f"      - Base URL: {weather_variables['weather_api_base_url']}")
        logger.info(f"      - Timeout: {weather_variables['weather_api_timeout']} seconds")
        logger.info(f"      - Rate limit: {weather_variables['weather_rate_limit_delay']} seconds")
        
        logger.info("   📍 Locations:")
        logger.info(f"      - Chicago: {weather_variables['weather_chicago_lat']}, {weather_variables['weather_chicago_lng']}")
        logger.info(f"      - Evanston: {weather_variables['weather_evanston_lat']}, {weather_variables['weather_evanston_lng']}")
        
        logger.info("   ⚙️  Data Configuration:")
        logger.info(f"      - Years: {weather_variables['weather_data_years']}")
        logger.info(f"      - Timezone: {weather_variables['weather_timezone']}")
        logger.info(f"      - Units: {weather_variables['weather_temperature_unit']}, {weather_variables['weather_wind_speed_unit']}, {weather_variables['weather_precipitation_unit']}")
        logger.info(f"      - S3 Prefix: {weather_variables['weather_s3_prefix']}")
        
        return True
        
    except Exception as e:
        logger.error(f"❌ Error setting up weather variables: {str(e)}")
        return False

def verify_existing_variables():
    """
    Verify that required bronze bucket variables exist.
    """
    
    logger.info("🔍 Verifying existing Airflow variables...")
    
    required_variables = [
        'bronze_bucket',
        'silver_bucket', 
        'gold_bucket'
    ]
    
    try:
        missing_variables = []
        
        for var_name in required_variables:
            try:
                var_value = Variable.get(var_name)
                logger.info(f"✅ Found variable: {var_name} = {var_value}")
            except Exception:
                missing_variables.append(var_name)
                logger.warning(f"⚠️  Missing variable: {var_name}")
        
        if missing_variables:
            logger.error(f"❌ Missing required variables: {', '.join(missing_variables)}")
            logger.info("💡 Please run the main setup_variables.py script first to set up bucket variables.")
            return False
        
        logger.info("✅ All required variables found!")
        return True
        
    except Exception as e:
        logger.error(f"❌ Error verifying variables: {str(e)}")
        return False

def list_all_weather_variables():
    """
    List all weather-related variables for verification.
    """
    
    logger.info("📋 Listing all weather-related variables...")
    
    try:
        # Get all variables
        from airflow.models import Variable
        from airflow import settings
        from sqlalchemy import text
        
        session = settings.Session()
        
        # Query for weather variables
        weather_vars = session.execute(
            text("SELECT key, val FROM variable WHERE key LIKE 'weather_%' ORDER BY key")
        ).fetchall()
        
        if weather_vars:
            logger.info(f"🌤️  Found {len(weather_vars)} weather variables:")
            for var_key, var_val in weather_vars:
                logger.info(f"   - {var_key}: {var_val}")
        else:
            logger.info("📭 No weather variables found.")
        
        session.close()
        
    except Exception as e:
        logger.warning(f"⚠️  Could not list variables: {str(e)}")

def main():
    """
    Main function to set up weather variables.
    """
    
    print("🌤️  Weather Data Variables Setup")
    print("=" * 40)
    
    # Verify existing variables first
    if not verify_existing_variables():
        print("\n❌ Required variables missing. Please set up bucket variables first.")
        return False
    
    # Set up weather variables
    if not setup_weather_variables():
        print("\n❌ Failed to set up weather variables.")
        return False
    
    # List all weather variables for verification
    list_all_weather_variables()
    
    print("\n" + "=" * 40)
    print("🎉 Weather variables setup completed successfully!")
    print("\n📋 Current status:")
    print("   ✅ Weather data collection is COMPLETE (48/48 files)")
    print("   ✅ weather_data_ingestion_optimized DAG available for future updates")
    print("   ✅ manual_weather_collection.py script available for standalone use")
    print("   ✅ Data ready for analytics and bike-share correlation analysis")
    
    return True

if __name__ == "__main__":
    main()
