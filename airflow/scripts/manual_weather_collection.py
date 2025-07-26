"""
Manual Weather Data Collection Script

This script provides a manual method to collect the remaining weather data files
when the Airflow DAG encounters issues. It can be run independently to complete
the weather data collection.

Usage:
    python manual_weather_collection.py

Author: Analytics Engineering Team
Created: July 27, 2025
"""

import requests
import pandas as pd
import boto3
from botocore.exceptions import ClientError
import logging
import time
from datetime import datetime
from typing import Dict, List, Tuple
import json
from calendar import monthrange

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Configuration
LOCATIONS = {
    'chicago': {'lat': 41.8781, 'lon': -87.6298},
    'evanston': {'lat': 42.0451, 'lon': -87.6877}
}

YEARS = [2023, 2024]
MONTHS = list(range(1, 13))

API_BASE_URL = "https://archive-api.open-meteo.com/v1/archive"
API_RATE_LIMIT_DELAY = 2
BUCKET_NAME = 'divvybikes-dev-bronze-96wb3c9c'

# Weather variables to collect
WEATHER_VARIABLES = [
    'temperature_2m_max', 'temperature_2m_min', 'temperature_2m_mean',
    'apparent_temperature_max', 'apparent_temperature_min', 'apparent_temperature_mean',
    'precipitation_sum', 'rain_sum', 'snowfall_sum', 'snow_depth_max',
    'wind_speed_10m_max', 'wind_gusts_10m_max', 'wind_direction_10m_dominant',
    'cloud_cover_mean', 'relative_humidity_2m_max', 'relative_humidity_2m_min',
    'relative_humidity_2m_mean'
]


def get_s3_client():
    """Initialize S3 client with proper error handling."""
    try:
        return boto3.client('s3')
    except Exception as e:
        logger.error(f"Failed to initialize S3 client: {e}")
        raise


def check_existing_files(s3_client) -> List[str]:
    """
    Check which weather files already exist in S3.
    
    Returns:
        List of existing S3 keys
    """
    try:
        response = s3_client.list_objects_v2(
            Bucket=BUCKET_NAME,
            Prefix='weather-data/'
        )
        
        existing_files = []
        if 'Contents' in response:
            existing_files = [obj['Key'] for obj in response['Contents'] if obj['Key'].endswith('.csv')]
        
        logger.info(f"Found {len(existing_files)} existing weather files in S3")
        return existing_files
        
    except ClientError as e:
        logger.error(f"Failed to list S3 objects: {e}")
        raise


def get_missing_files(existing_files: List[str]) -> List[Tuple[str, int, int]]:
    """
    Determine which files are missing.
    
    Args:
        existing_files: List of existing S3 keys
    
    Returns:
        List of tuples (location, year, month) for missing files
    """
    missing_files = []
    existing_set = set(existing_files)
    
    for location in LOCATIONS.keys():
        for year in YEARS:
            for month in MONTHS:
                filename = f"weather_data_{location}_{year}_{month:02d}.csv"
                s3_key = f"weather-data/location={location}/year={year}/month={month:02d}/{filename}"
                
                if s3_key not in existing_set:
                    missing_files.append((location, year, month))
    
    logger.info(f"Found {len(missing_files)} missing files to collect")
    return missing_files


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
                logger.info(f"Fetching weather data for {location} {year}-{month:02d} (attempt {attempt + 1})")
                response = requests.get(API_BASE_URL, params=params, timeout=30)
                response.raise_for_status()
                break
            except requests.exceptions.RequestException as e:
                if attempt == max_retries - 1:
                    raise Exception(f"API request failed after {max_retries} attempts: {str(e)}")
                logger.warning(f"API request attempt {attempt + 1} failed, retrying...")
                time.sleep(API_RATE_LIMIT_DELAY * (attempt + 1))
        
        # Parse response
        data = response.json()
        
        if 'daily' not in data:
            raise Exception(f"Invalid API response for {location} {year}-{month:02d}")
        
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
        
        logger.info(f"Successfully processed {len(df)} days for {location} {year}-{month:02d}")
        return df
        
    except Exception as e:
        logger.error(f"Failed to fetch weather data for {location} {year}-{month:02d}: {str(e)}")
        raise


def upload_to_s3(s3_client, df: pd.DataFrame, location: str, year: int, month: int) -> str:
    """
    Upload weather data to S3.
    
    Args:
        s3_client: Boto3 S3 client
        df: Weather data DataFrame
        location: Location name
        year: Year
        month: Month
    
    Returns:
        S3 key of uploaded file
    """
    try:
        # Generate filename and S3 key
        filename = f"weather_data_{location}_{year}_{month:02d}.csv"
        s3_key = f"weather-data/location={location}/year={year}/month={month:02d}/{filename}"
        
        # Convert to CSV
        csv_content = df.to_csv(index=False)
        
        # Upload to S3
        s3_client.put_object(
            Bucket=BUCKET_NAME,
            Key=s3_key,
            Body=csv_content.encode('utf-8'),
            ContentType='text/csv'
        )
        
        logger.info(f"Successfully uploaded {s3_key}")
        return s3_key
        
    except ClientError as e:
        logger.error(f"Failed to upload to S3: {e}")
        raise


def main():
    """Main execution function."""
    try:
        logger.info("🌤️  Starting manual weather data collection")
        logger.info("=" * 60)
        
        # Initialize S3 client
        s3_client = get_s3_client()
        
        # Check existing files
        existing_files = check_existing_files(s3_client)
        missing_files = get_missing_files(existing_files)
        
        if not missing_files:
            logger.info("✅ All weather files already exist! Collection is complete.")
            return
        
        logger.info(f"📋 Starting collection of {len(missing_files)} missing files...")
        
        # Process missing files
        successful_uploads = []
        failed_uploads = []
        
        for i, (location, year, month) in enumerate(missing_files, 1):
            try:
                logger.info(f"[{i}/{len(missing_files)}] Processing {location} {year}-{month:02d}")
                
                # Fetch weather data
                df = fetch_weather_data_for_month(location, year, month)
                
                # Upload to S3
                s3_key = upload_to_s3(s3_client, df, location, year, month)
                successful_uploads.append(s3_key)
                
                # Rate limiting
                time.sleep(API_RATE_LIMIT_DELAY)
                
            except Exception as e:
                logger.error(f"Failed to process {location} {year}-{month:02d}: {e}")
                failed_uploads.append((location, year, month, str(e)))
                continue
        
        # Final report
        logger.info("=" * 60)
        logger.info("📊 MANUAL COLLECTION COMPLETE")
        logger.info(f"Successful uploads: {len(successful_uploads)}")
        logger.info(f"Failed uploads: {len(failed_uploads)}")
        
        if successful_uploads:
            logger.info("\n✅ Successfully uploaded:")
            for key in successful_uploads:
                logger.info(f"   {key}")
        
        if failed_uploads:
            logger.info("\n❌ Failed uploads:")
            for location, year, month, error in failed_uploads:
                logger.info(f"   {location} {year}-{month:02d}: {error}")
        
        # Check final status
        final_existing = check_existing_files(s3_client)
        completion_percentage = (len(final_existing) / 48) * 100
        
        logger.info(f"\n📈 Final Status:")
        logger.info(f"Total files: {len(final_existing)}/48 ({completion_percentage:.1f}%)")
        
        if len(final_existing) == 48:
            logger.info("🎉 Weather data collection is now COMPLETE!")
        else:
            logger.info(f"⚠️  Still missing {48 - len(final_existing)} files")
        
        logger.info("=" * 60)
        
    except Exception as e:
        logger.error(f"Manual collection failed: {e}")
        raise


if __name__ == "__main__":
    main()
