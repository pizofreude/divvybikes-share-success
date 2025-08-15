-- Alternative: Create Glue Catalog Tables via AWS CLI
-- This script creates the Glue catalog tables directly using AWS CLI
-- Run this instead of Terraform to avoid permission issues

echo "Creating Glue catalog table for divvy_trips..."
aws glue create-table \
    --database-name divvybikes_bronze_db \
    --table-input '{
        "Name": "divvy_trips",
        "Description": "Divvy bike share trip data partitioned by year and month",
        "TableType": "EXTERNAL_TABLE",
        "Parameters": {
            "skip.header.line.count": "1",
            "delimiter": ",",
            "classification": "csv"
        },
        "StorageDescriptor": {
            "Location": "s3://divvybikes-dev-bronze-96wb3c9c/divvy-trips/",
            "InputFormat": "org.apache.hadoop.mapred.TextInputFormat",
            "OutputFormat": "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat",
            "SerdeInfo": {
                "SerializationLibrary": "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe",
                "Parameters": {
                    "field.delim": ","
                }
            },
            "Columns": [
                {"Name": "ride_id", "Type": "string"},
                {"Name": "rideable_type", "Type": "string"},
                {"Name": "started_at", "Type": "timestamp"},
                {"Name": "ended_at", "Type": "timestamp"},
                {"Name": "start_station_name", "Type": "string"},
                {"Name": "start_station_id", "Type": "string"},
                {"Name": "end_station_name", "Type": "string"},
                {"Name": "end_station_id", "Type": "string"},
                {"Name": "start_lat", "Type": "double"},
                {"Name": "start_lng", "Type": "double"},
                {"Name": "end_lat", "Type": "double"},
                {"Name": "end_lng", "Type": "double"},
                {"Name": "member_casual", "Type": "string"}
            ]
        },
        "PartitionKeys": [
            {"Name": "year", "Type": "string"},
            {"Name": "month", "Type": "string"}
        ]
    }' --region ap-southeast-2

echo "Creating Glue catalog table for weather_data..."
aws glue create-table \
    --database-name divvybikes_bronze_db \
    --table-input '{
        "Name": "weather_data",
        "Description": "Weather data partitioned by location, year, and month",
        "TableType": "EXTERNAL_TABLE",
        "Parameters": {
            "skip.header.line.count": "1",
            "delimiter": ",",
            "classification": "csv"
        },
        "StorageDescriptor": {
            "Location": "s3://divvybikes-dev-bronze-96wb3c9c/weather-data/",
            "InputFormat": "org.apache.hadoop.mapred.TextInputFormat",
            "OutputFormat": "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat",
            "SerdeInfo": {
                "SerializationLibrary": "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe",
                "Parameters": {
                    "field.delim": ","
                }
            },
            "Columns": [
                {"Name": "time", "Type": "date"},
                {"Name": "temperature_2m_max", "Type": "double"},
                {"Name": "temperature_2m_min", "Type": "double"},
                {"Name": "temperature_2m_mean", "Type": "double"},
                {"Name": "apparent_temperature_max", "Type": "double"},
                {"Name": "apparent_temperature_min", "Type": "double"},
                {"Name": "apparent_temperature_mean", "Type": "double"},
                {"Name": "precipitation_sum", "Type": "double"},
                {"Name": "rain_sum", "Type": "double"},
                {"Name": "snowfall_sum", "Type": "double"},
                {"Name": "wind_speed_10m_max", "Type": "double"},
                {"Name": "wind_gusts_10m_max", "Type": "double"},
                {"Name": "wind_direction_10m_dominant", "Type": "int"},
                {"Name": "cloud_cover_mean", "Type": "int"}
            ]
        },
        "PartitionKeys": [
            {"Name": "location", "Type": "string"},
            {"Name": "year", "Type": "string"},
            {"Name": "month", "Type": "string"}
        ]
    }' --region ap-southeast-2

echo "Creating Glue catalog table for gbfs_stations..."
aws glue create-table \
    --database-name divvybikes_bronze_db \
    --table-input '{
        "Name": "gbfs_stations",
        "Description": "GBFS station information partitioned by endpoint, year, month, and day",
        "TableType": "EXTERNAL_TABLE",
        "Parameters": {
            "classification": "json"
        },
        "StorageDescriptor": {
            "Location": "s3://divvybikes-dev-bronze-96wb3c9c/gbfs-data/",
            "InputFormat": "org.apache.hadoop.mapred.TextInputFormat",
            "OutputFormat": "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat",
            "SerdeInfo": {
                "SerializationLibrary": "org.openx.data.jsonserde.JsonSerDe"
            },
            "Columns": [
                {"Name": "station_id", "Type": "string"},
                {"Name": "name", "Type": "string"},
                {"Name": "short_name", "Type": "string"},
                {"Name": "lat", "Type": "double"},
                {"Name": "lon", "Type": "double"},
                {"Name": "capacity", "Type": "int"},
                {"Name": "legacy_id", "Type": "string"}
            ]
        },
        "PartitionKeys": [
            {"Name": "endpoint", "Type": "string"},
            {"Name": "year", "Type": "string"},
            {"Name": "month", "Type": "string"},
            {"Name": "day", "Type": "string"}
        ]
    }' --region ap-southeast-2

echo "Verifying Glue tables were created..."
aws glue get-tables --database-name divvybikes_bronze_db --region ap-southeast-2
