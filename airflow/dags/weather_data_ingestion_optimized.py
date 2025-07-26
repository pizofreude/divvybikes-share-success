"""
Optimized Weather Data Ingestion DAG for Open-Meteo Historical Weather API

This DAG implements an improved architecture with:
1. Task splitting by location and year for better parallelization
2. Checkpoint/resume functionality to handle partial failures
3. Increased timeout limits for comprehensive processing
4. Better error handling and retry logic

Author: Analytics Engineering Team
Created: July 27, 2025
"""

from datetime import datetime, timedelta
import requests
import pandas as pd
import logging
from typing import Dict, List, Any
import time

from airflow import DAG
from airflow.decorators import task
from airflow.providers.amazon.aws.hooks.s3 import S3Hook
from airflow.exceptions import AirflowException
from airflow.models import Variable

# Enhanced DAG configuration
default_args = {
    'owner': 'analytics-engineering',
    'depends_on_past': False,
    'start_date': datetime(2025, 7, 27),
    'email_on_failure': True,
    'email_on_retry': False,
    'retries': 3,
    'retry_delay': timedelta(minutes=5),
    'execution_timeout': timedelta(minutes=30),  # Increased timeout per task
    'sla': timedelta(hours=2),
}

dag = DAG(
    'weather_data_ingestion_optimized',
    default_args=default_args,
    description='Optimized weather data collection with task splitting and checkpoints',
    schedule=None,  # Manual trigger only
    catchup=False,
    max_active_runs=1,
    tags=['weather', 'api', 'bronze-layer', 'optimized']
)

# Configuration constants
LOCATIONS = {
    'chicago': {'lat': 41.8781, 'lon': -87.6298},
    'evanston': {'lat': 42.0451, 'lon': -87.6877}
}

YEARS = [2023, 2024]
MONTHS = list(range(1, 13))

API_BASE_URL = "https://archive-api.open-meteo.com/v1/archive"
API_RATE_LIMIT_DELAY = 2  # Increased delay for better reliability
BUCKET_NAME = Variable.get('bronze_bucket', 'divvybikes-dev-bronze-96wb3c9c')

# Weather variables to collect
WEATHER_VARIABLES = [
    'temperature_2m_max', 'temperature_2m_min', 'temperature_2m_mean',
    'apparent_temperature_max', 'apparent_temperature_min', 'apparent_temperature_mean',
    'precipitation_sum', 'rain_sum', 'snowfall_sum', 'snow_depth_max',
    'wind_speed_10m_max', 'wind_gusts_10m_max', 'wind_direction_10m_dominant',
    'cloud_cover_mean', 'relative_humidity_2m_max', 'relative_humidity_2m_min',
    'relative_humidity_2m_mean'
]


@task(task_id='validate_aws_connectivity')
def validate_aws_connectivity() -> Dict[str, Any]:
    """
    Validate AWS S3 connectivity and bucket access.
    
    Returns:
        Dict containing validation results
    """
    try:
        s3_hook = S3Hook(aws_conn_id='aws_default')
        
        # Test bucket access
        if not s3_hook.check_for_bucket(BUCKET_NAME):
            raise AirflowException(f"Bucket {BUCKET_NAME} not accessible")
        
        # Test write permissions
        test_key = 'weather-data/test/connectivity_test.txt'
        s3_hook.load_string(
            string_data="AWS connectivity test",
            key=test_key,
            bucket_name=BUCKET_NAME,
            replace=True
        )
        
        # Clean up test file
        s3_hook.delete_objects(bucket=BUCKET_NAME, keys=[test_key])
        
        logging.info(f"✅ AWS S3 connectivity validated for bucket: {BUCKET_NAME}")
        return {
            'status': 'success',
            'bucket': BUCKET_NAME,
            'timestamp': datetime.now().isoformat()
        }
        
    except Exception as e:
        logging.error(f"❌ AWS connectivity validation failed: {str(e)}")
        raise AirflowException(f"AWS connectivity validation failed: {str(e)}")


@task(task_id='check_existing_files')
def check_existing_files() -> Dict[str, List[str]]:
    """
    Check which weather files already exist in S3 to implement checkpoint functionality.
    
    Returns:
        Dict with existing and missing files
    """
    try:
        s3_hook = S3Hook(aws_conn_id='aws_default')
        
        # Get list of existing files
        existing_keys = s3_hook.list_keys(
            bucket_name=BUCKET_NAME,
            prefix='weather-data/'
        ) or []
        
        # Generate list of all expected files
        expected_files = []
        existing_files = []
        missing_files = []
        
        for location in LOCATIONS.keys():
            for year in YEARS:
                for month in MONTHS:
                    filename = f"weather_data_{location}_{year}_{month:02d}.csv"
                    expected_key = f"weather-data/location={location}/year={year}/month={month:02d}/{filename}"
                    expected_files.append(expected_key)
                    
                    if expected_key in existing_keys:
                        existing_files.append(expected_key)
                    else:
                        missing_files.append(expected_key)
        
        logging.info(f"📊 Checkpoint Status:")
        logging.info(f"   Total expected: {len(expected_files)}")
        logging.info(f"   Already exists: {len(existing_files)}")
        logging.info(f"   Missing: {len(missing_files)}")
        
        return {
            'existing_files': existing_files,
            'missing_files': missing_files,
            'total_expected': len(expected_files),
            'completion_percentage': (len(existing_files) / len(expected_files)) * 100
        }
        
    except Exception as e:
        logging.error(f"❌ Failed to check existing files: {str(e)}")
        raise AirflowException(f"Failed to check existing files: {str(e)}")


def fetch_weather_data_for_month(location: str, year: int, month: int) -> pd.DataFrame:
    """
    Fetch weather data for a specific location, year, and month.
    
    Args:
        location: Location name (chicago/evanston)
        year: Year (2023/2024)
        month: Month (1-12)
    
    Returns:
        DataFrame with weather data
    """
    try:
        coords = LOCATIONS[location]
        
        # Calculate date range for the month
        from calendar import monthrange
        _, last_day = monthrange(year, month)
        start_date = f"{year}-{month:02d}-01"
        end_date = f"{year}-{month:02d}-{last_day}"
        
        # API parameters
        params = {
            'latitude': coords['lat'],
            'longitude': coords['lon'],
            'start_date': start_date,
            'end_date': end_date,
            'daily': ','.join(WEATHER_VARIABLES),
            'timezone': 'America/Chicago'
        }
        
        # Make API request with retry logic
        max_retries = 3
        for attempt in range(max_retries):
            try:
                logging.info(f"🌤️  Fetching weather data for {location} {year}-{month:02d} (attempt {attempt + 1})")
                response = requests.get(API_BASE_URL, params=params, timeout=30)
                response.raise_for_status()
                break
            except requests.exceptions.RequestException as e:
                if attempt == max_retries - 1:
                    raise AirflowException(f"API request failed after {max_retries} attempts: {str(e)}")
                logging.warning(f"⚠️  API request attempt {attempt + 1} failed, retrying...")
                time.sleep(API_RATE_LIMIT_DELAY * (attempt + 1))
        
        # Parse response
        data = response.json()
        
        if 'daily' not in data:
            raise AirflowException(f"Invalid API response for {location} {year}-{month:02d}")
        
        # Create DataFrame
        daily_data = data['daily']
        df = pd.DataFrame({
            'date': pd.to_datetime(daily_data['time']),
            **{var: daily_data.get(var, [None] * len(daily_data['time'])) 
               for var in WEATHER_VARIABLES}
        })
        
        # Add metadata
        df['location_key'] = location
        df['location_name'] = location.title()
        df['latitude'] = coords['lat']
        df['longitude'] = coords['lon']
        df['year'] = year
        df['month'] = month
        df['fetched_at'] = datetime.now().strftime('%Y-%m-%d %H:%M:%S UTC')
        
        # Add derived metrics
        df['temperature_2m_range'] = df['temperature_2m_max'] - df['temperature_2m_min']
        df['apparent_temperature_range'] = df['apparent_temperature_max'] - df['apparent_temperature_min']
        df['humidity_range'] = df['relative_humidity_2m_max'] - df['relative_humidity_2m_min']
        
        # Weather categorization
        def categorize_weather(row):
            if pd.isna(row['precipitation_sum']) or row['precipitation_sum'] == 0:
                if row['cloud_cover_mean'] < 40:
                    return 'clear'
                elif row['cloud_cover_mean'] < 80:
                    return 'partly_cloudy'
                else:
                    return 'cloudy'
            elif row['snowfall_sum'] > 0:
                return 'snowy'
            elif row['precipitation_sum'] > 10:
                return 'rainy'
            else:
                return 'light_rain'
        
        df['weather_category'] = df.apply(categorize_weather, axis=1)
        
        # Comfort index (simplified)
        def calculate_comfort_index(row):
            temp_score = max(0, min(100, 100 - abs(row['temperature_2m_mean'] - 20) * 3))
            precip_score = max(0, 100 - row['precipitation_sum'] * 10)
            wind_score = max(0, 100 - row['wind_speed_10m_max'] * 2)
            return (temp_score + precip_score + wind_score) / 3
        
        df['comfort_index'] = df.apply(calculate_comfort_index, axis=1)
        
        logging.info(f"✅ Successfully processed {len(df)} days for {location} {year}-{month:02d}")
        return df
        
    except Exception as e:
        logging.error(f"❌ Failed to fetch weather data for {location} {year}-{month:02d}: {str(e)}")
        raise AirflowException(f"Failed to fetch weather data for {location} {year}-{month:02d}: {str(e)}")


@task(task_id='process_chicago_2023')
def process_chicago_2023(existing_files_info: Dict[str, Any]) -> Dict[str, Any]:
    """Process weather data for Chicago 2023 with checkpoint awareness."""
    return process_location_year('chicago', 2023, existing_files_info)


@task(task_id='process_chicago_2024')
def process_chicago_2024(existing_files_info: Dict[str, Any]) -> Dict[str, Any]:
    """Process weather data for Chicago 2024 with checkpoint awareness."""
    return process_location_year('chicago', 2024, existing_files_info)


@task(task_id='process_evanston_2023')
def process_evanston_2023(existing_files_info: Dict[str, Any]) -> Dict[str, Any]:
    """Process weather data for Evanston 2023 with checkpoint awareness."""
    return process_location_year('evanston', 2023, existing_files_info)


@task(task_id='process_evanston_2024')
def process_evanston_2024(existing_files_info: Dict[str, Any]) -> Dict[str, Any]:
    """Process weather data for Evanston 2024 with checkpoint awareness."""
    return process_location_year('evanston', 2024, existing_files_info)


def process_location_year(location: str, year: int, existing_files_info: Dict[str, Any]) -> Dict[str, Any]:
    """
    Process weather data for a specific location and year.
    
    Args:
        location: Location name
        year: Year to process
        existing_files_info: Information about existing files from checkpoint
    
    Returns:
        Processing summary
    """
    try:
        s3_hook = S3Hook(aws_conn_id='aws_default')
        existing_files = set(existing_files_info['existing_files'])
        
        processed_files = []
        skipped_files = []
        failed_files = []
        
        for month in MONTHS:
            filename = f"weather_data_{location}_{year}_{month:02d}.csv"
            s3_key = f"weather-data/location={location}/year={year}/month={month:02d}/{filename}"
            
            # Check if file already exists (checkpoint functionality)
            if s3_key in existing_files:
                logging.info(f"⏭️  Skipping {location} {year}-{month:02d} - file already exists")
                skipped_files.append(s3_key)
                continue
            
            try:
                # Fetch data for this month
                df = fetch_weather_data_for_month(location, year, month)
                
                # Convert to CSV
                csv_content = df.to_csv(index=False)
                
                # Upload to S3
                s3_hook.load_string(
                    string_data=csv_content,
                    key=s3_key,
                    bucket_name=BUCKET_NAME,
                    replace=True
                )
                
                processed_files.append(s3_key)
                logging.info(f"✅ Uploaded {s3_key}")
                
                # Rate limiting
                time.sleep(API_RATE_LIMIT_DELAY)
                
            except Exception as e:
                logging.error(f"❌ Failed to process {location} {year}-{month:02d}: {str(e)}")
                failed_files.append({'key': s3_key, 'error': str(e)})
                continue
        
        # Summary
        summary = {
            'location': location,
            'year': year,
            'processed_files': processed_files,
            'skipped_files': skipped_files,
            'failed_files': failed_files,
            'total_processed': len(processed_files),
            'total_skipped': len(skipped_files),
            'total_failed': len(failed_files),
            'success_rate': len(processed_files) / (len(processed_files) + len(failed_files)) * 100 if (len(processed_files) + len(failed_files)) > 0 else 100
        }
        
        logging.info(f"📊 {location.title()} {year} Summary:")
        logging.info(f"   Processed: {summary['total_processed']}")
        logging.info(f"   Skipped: {summary['total_skipped']}")
        logging.info(f"   Failed: {summary['total_failed']}")
        logging.info(f"   Success Rate: {summary['success_rate']:.1f}%")
        
        return summary
        
    except Exception as e:
        logging.error(f"❌ Failed to process {location} {year}: {str(e)}")
        raise AirflowException(f"Failed to process {location} {year}: {str(e)}")


@task(task_id='generate_final_report')
def generate_final_report(chicago_2023: Dict[str, Any], chicago_2024: Dict[str, Any], 
                         evanston_2023: Dict[str, Any], evanston_2024: Dict[str, Any]) -> Dict[str, Any]:
    """
    Generate final processing report with overall statistics.
    
    Args:
        chicago_2023, chicago_2024, evanston_2023, evanston_2024: Processing summaries
    
    Returns:
        Final report summary
    """
    try:
        summaries = [chicago_2023, chicago_2024, evanston_2023, evanston_2024]
        
        total_processed = sum(s['total_processed'] for s in summaries)
        total_skipped = sum(s['total_skipped'] for s in summaries)
        total_failed = sum(s['total_failed'] for s in summaries)
        total_expected = 48  # 2 locations × 2 years × 12 months
        
        # Calculate current status
        s3_hook = S3Hook(aws_conn_id='aws_default')
        current_files = s3_hook.list_keys(
            bucket_name=BUCKET_NAME,
            prefix='weather-data/'
        ) or []
        
        current_count = len([f for f in current_files if f.endswith('.csv')])
        completion_percentage = (current_count / total_expected) * 100
        
        final_report = {
            'run_timestamp': datetime.now().isoformat(),
            'total_expected_files': total_expected,
            'current_files_count': current_count,
            'completion_percentage': completion_percentage,
            'this_run_processed': total_processed,
            'this_run_skipped': total_skipped,
            'this_run_failed': total_failed,
            'location_summaries': {
                'chicago_2023': chicago_2023,
                'chicago_2024': chicago_2024,
                'evanston_2023': evanston_2023,
                'evanston_2024': evanston_2024
            },
            'status': 'completed' if current_count == total_expected else 'partial',
            'next_steps': 'Weather data collection completed successfully!' if current_count == total_expected 
                         else f'Weather data collection {completion_percentage:.1f}% complete. {total_expected - current_count} files remaining.'
        }
        
        logging.info("📈 FINAL WEATHER DATA INGESTION REPORT")
        logging.info("=" * 50)
        logging.info(f"Expected Files: {total_expected}")
        logging.info(f"Current Files: {current_count}")
        logging.info(f"Completion: {completion_percentage:.1f}%")
        logging.info(f"This Run - Processed: {total_processed}, Skipped: {total_skipped}, Failed: {total_failed}")
        logging.info(f"Status: {final_report['status'].upper()}")
        logging.info(f"Next Steps: {final_report['next_steps']}")
        logging.info("=" * 50)
        
        return final_report
        
    except Exception as e:
        logging.error(f"❌ Failed to generate final report: {str(e)}")
        raise AirflowException(f"Failed to generate final report: {str(e)}")


# Define task dependencies with proper DAG context
with dag:
    aws_validation = validate_aws_connectivity()
    existing_files_check = check_existing_files()

    # Location/year processing tasks
    chicago_2023_task = process_chicago_2023(existing_files_check)
    chicago_2024_task = process_chicago_2024(existing_files_check)
    evanston_2023_task = process_evanston_2023(existing_files_check)
    evanston_2024_task = process_evanston_2024(existing_files_check)

    # Final report
    final_report = generate_final_report(
        chicago_2023_task,
        chicago_2024_task,
        evanston_2023_task,
        evanston_2024_task
    )

    # Set up dependencies
    aws_validation >> existing_files_check
    existing_files_check >> [chicago_2023_task, chicago_2024_task, evanston_2023_task, evanston_2024_task]
    [chicago_2023_task, chicago_2024_task, evanston_2023_task, evanston_2024_task] >> final_report
