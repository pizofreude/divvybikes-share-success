# Weather Data Ingestion Documentation

## Overview

The Weather Data Ingestion system collects historical weather data from the Open-Meteo API for Chicago and Evanston locations covering the years 2023-2024. This data is essential for analyzing the correlation between weather conditions and bike-sharing usage patterns.

**Status**: ✅ **COMPLETED** - All 48 weather files successfully collected and stored in S3 Bronze layer.

## Implementation Architecture

The weather data collection was implemented using multiple approaches for reliability:

1. **Primary DAG**: `weather_data_ingestion_optimized.py` - Multi-task architecture with checkpoint functionality
2. **Manual Collection**: `manual_weather_collection.py` - Standalone script for direct execution
3. **Backup Methods**: Both approaches ensure comprehensive data collection with fault tolerance

## Data Source

**API**: [Open-Meteo Historical Weather API](https://open-meteo.com/en/docs/historical-weather-api)

**Locations**:
- **Chicago**: 41.8781°N, -87.6298°W
- **Evanston**: 42.0451°N, -87.6877°W

**Time Period**: January 1, 2023 - December 31, 2024 (2 full years)

**Data Frequency**: Daily aggregated values

## Data Schema

### Weather Variables Collected

| Variable | Description | Unit | Example |
|----------|-------------|------|---------|
| `temperature_2m_max` | Maximum daily temperature | °C | 25.4 |
| `temperature_2m_min` | Minimum daily temperature | °C | 12.1 |
| `temperature_2m_mean` | Average daily temperature | °C | 18.7 |
| `apparent_temperature_max` | Maximum daily "feels like" temperature | °C | 27.2 |
| `apparent_temperature_min` | Minimum daily "feels like" temperature | °C | 10.5 |
| `apparent_temperature_mean` | Average daily "feels like" temperature | °C | 18.9 |
| `precipitation_sum` | Total daily precipitation | mm | 5.2 |
| `rain_sum` | Total daily rainfall | mm | 3.8 |
| `snowfall_sum` | Total daily snowfall | cm | 1.5 |
| `snow_depth_max` | Maximum snow depth | cm | 10.2 |
| `wind_speed_10m_max` | Maximum daily wind speed | km/h | 28.7 |
| `wind_gusts_10m_max` | Maximum daily wind gusts | km/h | 45.1 |
| `wind_direction_10m_dominant` | Dominant wind direction | degrees | 270 |
| `cloud_cover_mean` | Average cloud coverage | % | 65 |
| `relative_humidity_2m_max` | Maximum daily humidity | % | 85 |
| `relative_humidity_2m_min` | Minimum daily humidity | % | 45 |
| `relative_humidity_2m_mean` | Average daily humidity | % | 65 |

### Derived Metrics

| Variable | Description | Calculation | Purpose |
|----------|-------------|-------------|---------|
| `temperature_2m_range` | Daily temperature variation | max - min | Temperature stability indicator |
| `apparent_temperature_range` | Daily "feels like" variation | apparent_max - apparent_min | Comfort variation |
| `humidity_range` | Daily humidity variation | humidity_max - humidity_min | Humidity stability |
| `weather_category` | Weather condition category | Rule-based classification | Simplified weather grouping |
| `comfort_index` | Comfort index (0-100) | Weighted scoring algorithm | Overall comfort rating |

### Weather Categories

- **`clear`**: Low cloud cover (< 40%), no precipitation
- **`partly_cloudy`**: Moderate cloud cover (40-80%), no precipitation
- **`cloudy`**: High cloud cover (> 80%), no precipitation
- **`light_rain`**: Light precipitation (< 10mm rain)
- **`rainy`**: Heavy precipitation (> 10mm rain)
- **`snowy`**: Any snowfall recorded

### Metadata Fields

| Field | Description | Example |
|-------|-------------|---------|
| `date` | Date of observation | 2023-01-15 |
| `time` | Full timestamp | 2023-01-15T00:00:00 |
| `year` | Year (for partitioning) | 2023 |
| `month` | Month (for partitioning) | 1 |
| `day` | Day of month | 15 |
| `day_of_week` | Day of week (0=Monday) | 6 |
| `day_of_year` | Day of year | 15 |
| `location_key` | Location identifier | chicago |
| `location_name` | Location display name | Chicago |
| `latitude` | Location latitude | 41.8781 |
| `longitude` | Location longitude | -87.6298 |
| `fetched_at` | Data ingestion timestamp | 2025-07-26T22:01:00Z |

## Data Storage Structure

### S3 Bucket Structure

```
s3://divvybikes-dev-bronze-96wb3c9c/weather-data/
├── location=chicago/
│   ├── year=2023/
│   │   ├── month=01/
│   │   │   └── weather_data_chicago_2023_01.csv
│   │   ├── month=02/
│   │   │   └── weather_data_chicago_2023_02.csv
│   │   └── ... (12 months)
│   └── year=2024/
│       ├── month=01/
│       │   └── weather_data_chicago_2024_01.csv
│       └── ... (12 months)
└── location=evanston/
    ├── year=2023/
    │   └── ... (12 months)
    └── year=2024/
        └── ... (12 months)
```

### File Naming Convention

**Pattern**: `weather_data_{location}_{year}_{month:02d}.csv`

**Examples**:
- `weather_data_chicago_2023_01.csv`
- `weather_data_evanston_2024_12.csv`

## DAG Configuration

### Primary DAG: weather_data_ingestion_optimized.py

- **Schedule**: Manual trigger (on-demand execution)
- **Start Date**: July 27, 2025
- **Catchup**: Disabled
- **Max Active Runs**: 1
- **Architecture**: Multi-task with location/year splitting for parallel processing

### Enhanced Features

1. **Task Splitting**: Separate tasks for each location/year combination (chicago_2023, chicago_2024, evanston_2023, evanston_2024)
2. **Checkpoint Functionality**: Automatically skips already collected files
3. **Increased Timeouts**: 30-minute timeout per task for reliable processing
4. **Enhanced Error Handling**: Comprehensive retry logic and failure recovery
5. **Progress Tracking**: Real-time monitoring of collection status

### Tasks Overview

1. **`validate_aws_connectivity`**: Validates S3 bucket access
2. **`check_existing_files`**: Implements checkpoint functionality by checking existing S3 files
3. **`process_chicago_2023`**: Collects Chicago 2023 weather data (12 months)
4. **`process_chicago_2024`**: Collects Chicago 2024 weather data (12 months)
5. **`process_evanston_2023`**: Collects Evanston 2023 weather data (12 months)
6. **`process_evanston_2024`**: Collects Evanston 2024 weather data (12 months)
7. **`generate_final_report`**: Provides comprehensive processing summary and status

### Manual Collection Script

**File**: `airflow/scripts/manual_weather_collection.py`

- **Purpose**: Standalone script for direct weather data collection
- **Usage**: `python manual_weather_collection.py`
- **Features**: Same data processing as DAG with checkpoint functionality
- **Success Rate**: 100% completion with 18 files collected in final run

### Rate Limiting

- **API Rate Limit**: 2 second delay between requests (increased for reliability)
- **Total API Calls**: 48 calls (2 locations × 2 years × 12 months)
- **Estimated Runtime**: 2-3 minutes for comprehensive collection
- **Retry Logic**: 3 attempts per API call with exponential backoff

## Data Quality

### API Reliability

- **Data Availability**: 1940-present (historical data)
- **Update Frequency**: Daily updates with ~5-day delay
- **Data Sources**: NOAA, ECMWF, national weather services
- **Quality Control**: Final quality-controlled data

### Validation Steps

1. **API Response Validation**: Ensures proper JSON structure
2. **Date Range Validation**: Verifies complete month coverage
3. **Data Type Validation**: Ensures numeric values where expected
4. **Upload Verification**: Confirms successful S3 upload

## Usage Examples

### Using the Optimized DAG

```bash
# Check if DAG is available in Airflow
docker exec -it airflow-airflow-webserver-1 airflow dags list | grep weather_data_ingestion_optimized

# Trigger the optimized weather data ingestion DAG
docker exec -it airflow-airflow-webserver-1 airflow dags trigger weather_data_ingestion_optimized

# Monitor DAG execution
docker exec -it airflow-airflow-webserver-1 airflow dags state weather_data_ingestion_optimized
```

### Using Manual Collection Script

```bash
# Run manual collection (used for final completion)
cd /c/workspace/divvybikes-share-success
python airflow/scripts/manual_weather_collection.py

# Check collection status
python -c "
import boto3
s3 = boto3.client('s3')
response = s3.list_objects_v2(Bucket='divvybikes-dev-bronze-96wb3c9c', Prefix='weather-data/')
files = [obj['Key'] for obj in response.get('Contents', []) if obj['Key'].endswith('.csv')]
print(f'Weather files: {len(files)}/48 ({len(files)/48*100:.1f}%)')
"
```

### Testing the Weather API

```bash
# Test API connectivity and data structure
cd /opt/airflow/scripts
python test_weather_api.py
```

## Data Integration

### Joining with Divvy Data

The weather data is partitioned by year/month to enable efficient joins with Divvy trip data:

```sql
-- Example join query for Silver layer transformation
SELECT 
    trips.ride_id,
    trips.started_at,
    trips.member_casual,
    weather.temperature_2m_mean,
    weather.precipitation_sum,
    weather.weather_category,
    weather.comfort_index
FROM divvy_trips trips
LEFT JOIN weather_data weather 
    ON DATE(trips.started_at) = weather.date
    AND weather.location_key = 'chicago'
WHERE trips.started_at >= '2023-01-01'
    AND trips.started_at < '2025-01-01'
```

### Analytics Use Cases

1. **Weather Impact Analysis**: How weather affects bike usage patterns
2. **Seasonal Trends**: Understanding seasonal variations in ridership
3. **Comfort Correlation**: Relationship between comfort index and trip duration
4. **Location Comparison**: Weather differences between Chicago and Evanston
5. **Predictive Modeling**: Using weather for demand forecasting

## Troubleshooting

### Common Issues

1. **API Rate Limiting**
   - **Symptom**: HTTP 429 errors
   - **Solution**: Increase `API_RATE_LIMIT_DELAY` in DAG configuration (currently set to 2 seconds)

2. **Network Timeouts**
   - **Symptom**: Connection timeout errors
   - **Solution**: Increase timeout value or retry logic (implemented in optimized version)

3. **S3 Permission Issues**
   - **Symptom**: Access denied errors
   - **Solution**: Verify AWS credentials and S3 bucket policies

4. **Missing Data**
   - **Symptom**: Empty API responses
   - **Solution**: Check date ranges and API parameter formatting

5. **Task Timeout/Partial Completion**
   - **Symptom**: DAG marked as "up_for_retry" or "failed" but some files uploaded successfully
   - **Solution**: ✅ **RESOLVED** - Use optimized DAG with task splitting and checkpoint functionality
   - **Progress Check**: Checkpoint functionality automatically detects and skips existing files

### Monitoring

- **DAG Success Rate**: Monitor for consistent successful runs
- **Data Completeness**: ✅ **ACHIEVED** - All 48 files collected and verified
- **File Sizes**: Consistent file sizes per month (verified)
- **API Response Times**: Stable performance with retry logic
- **Progress Tracking**: Checkpoint functionality provides real-time status

### Resolution Summary

All previous issues have been resolved through:

1. **Optimized DAG Architecture**: Task splitting eliminates timeout issues
2. **Checkpoint Functionality**: Automatic detection of existing files prevents redundant work
3. **Enhanced Error Handling**: Comprehensive retry logic and failure recovery
4. **Manual Collection Success**: 100% completion achieved via manual script
5. **Validation**: All 48 files verified in S3 with proper partitioning

## Current Status (as of July 27, 2025)

### Progress: 48/48 files (100% COMPLETE! 🎉)

| Location | Status | Files | Progress |
|----------|--------|-------|----------|
| Chicago 2023 | ✅ Complete | 12/12 | 100% |
| Chicago 2024 | ✅ Complete | 12/12 | 100% |
| Evanston 2023 | ✅ Complete | 12/12 | 100% |
| Evanston 2024 | ✅ Complete | 12/12 | 100% |

### Completion Summary

- **Total Files Collected**: 48/48 (100%)
- **Data Coverage**: Complete 2023-2024 weather data for both locations
- **Collection Method**: Manual script successfully completed all remaining files
- **Data Quality**: All files validated and stored with proper partitioning
- **Ready for Analytics**: Weather data now available for bike-share correlation analysis

## Future Enhancements

1. **Real-time Weather**: Add current weather data ingestion for live analytics
2. **Additional Locations**: Expand to more Chicago area locations (Oak Park, Wilmette, etc.)
3. **Hourly Data**: Collect hourly weather data for detailed time-series analysis
4. **Weather Alerts**: Integration with severe weather warnings and advisories
5. **Data Quality Metrics**: Enhanced validation and quality scoring algorithms
6. **Automated Updates**: Scheduled incremental updates for recent weather data
7. **Weather Forecasting**: Integration with weather prediction APIs for predictive analytics

## Project Impact

### Successfully Delivered

✅ **Complete Weather Dataset**: 48 files covering 2 years of daily weather data
✅ **Reliable Collection Pipeline**: Multiple collection methods ensuring data completeness  
✅ **Quality Data Processing**: 17 core variables + derived metrics for comprehensive analysis
✅ **Proper Data Partitioning**: S3 structure optimized for efficient querying and joins
✅ **Production-Ready Architecture**: Fault-tolerant system with checkpoint functionality

### Ready for Analytics

The weather data pipeline now provides a solid foundation for:
- **Weather Impact Analysis**: Correlation between weather conditions and bike usage
- **Seasonal Pattern Analysis**: Understanding seasonal ridership variations
- **Predictive Modeling**: Weather-based demand forecasting
- **Location Comparison**: Weather differences between Chicago and Evanston
- **Comfort Index Analytics**: Relationship between weather comfort and ride patterns

**Next Phase**: Integration with Divvy bike-share data for comprehensive analytics platform.
