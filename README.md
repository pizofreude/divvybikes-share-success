# Divvy Bike-Share Success

[![GitHub](https://img.shields.io/github/license/pizofreude/divvybikes-share-success)](https://github.com/pizofreude/divvybikes-share-success/blob/main/LICENSE)
![Project Status](https://img.shields.io/badge/status-in%20progress-yellow)

> **About:** A data engineering portfolio project analyzing Divvy bike-sharing patterns to uncover key differences between casual riders and annual members. Features Terraform IaC for AWS resource management, medallion architecture with S3 data lake, Docker-based Airflow for ETL orchestration, and Redshift Serverless for SQL analytics—all designed with cost optimization for small scale project.
 


## Project Status

🚧 **WIP**: This project is currently being developed and deployed. All planned features are work-in-progress.

### Key Features

[Placeholder text]

## Overview

[Placeholder text]

**Project Title:** Divvy Bike-Share Success

**Problem Statement:**

**Project Description:** 

**Project Structure:**

## Datasets

1. [Divvy Bikes Trip Data](https://divvy-tripdata.s3.amazonaws.com/index.html)
	<details> <summary>Data Dictionary</summary>
	    
	### **Dataset description**
	
	Historical trip data from Divvy, Chicago's bike share system, containing detailed records of individual bike trips. This dataset includes information about trip duration, starting and ending stations, rider types (member vs casual), and timestamps. This comprehensive dataset enables analysis of usage patterns, popular routes, and behavioral differences between annual members and casual riders.
	
	### **Variable definitions**
	
	| **Name in Dataset**      | **Variable**          | **Definition** |
	| ------------------------ | --------------------- | -------------- |
	| **ride_id (String)**     | Ride ID               | Unique identifier for each bike trip |
	| **rideable_type (String)** | Bike Type           | Type of bike used (classic, electric, docked) |
	| **started_at (Datetime)** | Trip Start Time      | Date and time when the trip started (format: YYYY-MM-DD HH:MM:SS) |
	| **ended_at (Datetime)**  | Trip End Time         | Date and time when the trip ended (format: YYYY-MM-DD HH:MM:SS) |
	| **start_station_name (String)** | Start Station  | Name of the station where the trip started |
	| **start_station_id (String)** | Start Station ID | Unique identifier for the starting station |
	| **end_station_name (String)** | End Station      | Name of the station where the trip ended |
	| **end_station_id (String)** | End Station ID     | Unique identifier for the ending station |
	| **start_lat (Float)**    | Start Latitude        | Latitude coordinate of the starting location |
	| **start_lng (Float)**    | Start Longitude       | Longitude coordinate of the starting location |
	| **end_lat (Float)**      | End Latitude          | Latitude coordinate of the ending location |
	| **end_lng (Float)**      | End Longitude         | Longitude coordinate of the ending location |
	| **member_casual (String)** | User Type           | Type of user (member = annual subscriber, casual = casual rider) |
	
	### **Last updated:**
	
	Monthly data available through June 2025
	
	### **Next update:**
	
	Monthly (new data released at the beginning of each month)
	
	### **Data source(s)**
	
	- Lyft Bikes and Scooters, LLC ("Bikeshare") which operates the City of Chicago's Divvy bikeshare system
	
	### **URLs to dataset**
	
	- https://divvy-tripdata.s3.amazonaws.com/index.html
	- Individual monthly files: https://divvy-tripdata.s3.amazonaws.com/YYYYMM-divvy-tripdata.zip
	
	### **License**
	
	This data is made available by Motivate International Inc. under a [Data License Agreement](https://ride.divvybikes.com/data-license-agreement). The data has been made available for non-commercial use only.
	
	</details>

2. [Divvy Bikes Station Information](https://gbfs.divvybikes.com/gbfs/en/station_information.json)
	<details> <summary>Data Dictionary</summary>
	    
	### **Dataset description**
	
	Current information about all Divvy bike stations in Chicago, including their locations, capacities, and status. This dataset provides a snapshot of the bike-sharing infrastructure, enabling spatial analysis of station distribution, capacity planning, and integration with trip data for comprehensive system analysis.
	
	### **Variable definitions**
	
	| **Name in Dataset**     | **Variable**           | **Definition** |
	| ----------------------- | ---------------------- | -------------- |
	| **station_id (String)** | Station ID             | Unique identifier for the bike station |
	| **name (String)**       | Station Name           | Name of the bike station |
	| **short_name (String)** | Short Name             | Abbreviated name of the station (if available) |
	| **lat (Float)**         | Latitude               | Latitude coordinate of the station location |
	| **lon (Float)**         | Longitude              | Longitude coordinate of the station location |
	| **capacity (Integer)**  | Capacity               | Total number of bike docks at the station |
	| **rental_uris (Object)** | Rental URIs           | Deep link URIs for mobile app integration |
	| **region_id (String)**  | Region ID              | Identifier for the region/service area containing the station |
	| **address (String)**    | Address                | Physical address of the station location |
	
	### **Station Status Variables (Real-time)**
	
	| **Name in Dataset**     | **Variable**           | **Definition** |
	| ----------------------- | ---------------------- | -------------- |
	| **num_bikes_available (Integer)** | Available Bikes | Number of bikes currently available for rental |
	| **num_docks_available (Integer)** | Available Docks | Number of empty docks available for bike returns |
	| **is_installed (Boolean)** | Installation Status | Whether the station is installed and operational |
	| **is_renting (Boolean)** | Rental Status         | Whether the station is currently accepting bike rentals |
	| **is_returning (Boolean)** | Return Status        | Whether the station is currently accepting bike returns |
	| **last_reported (Integer)** | Last Report Time    | Unix timestamp of the last status report |
	
	### **Last updated:**
	
	Real-time data, updated every minute
	
	### **Next update:**
	
	Continuously updated through GBFS feed
	
	### **Data source(s)**
	
	- Divvy Bikes GBFS (General Bikeshare Feed Specification) feed
	
	### **URLs to dataset**
	
	- Station Information: https://gbfs.divvybikes.com/gbfs/en/station_information.json
	- Station Status: https://gbfs.divvybikes.com/gbfs/en/station_status.json
	
	### **License**
	
	This data is made available through the GBFS standard. GBFS is an open data standard developed by the North American Bikeshare Association (NABSA).
	
	</details>

3. [Open-Meteo Historical Weather API](https://open-meteo.com/en/docs/historical-weather-api)
	<details> <summary>Data Dictionary</summary>
	    
	### **Dataset description**
	
	Historical weather data for Chicago accessed through the Open-Meteo Historical Weather API. This dataset provides hourly and daily weather variables including temperature, precipitation, wind speed, and other meteorological measurements. The weather data is crucial for analyzing how environmental conditions affect bike-sharing usage patterns, rider behavior, and trip durations.
	
	### **Variable definitions**
	
	| **Name in Dataset**     | **Variable**         | **Definition** |
	| ----------------------- | -------------------- | -------------- |
	| **time (Datetime)**     | Timestamp            | Date and time of weather observation (ISO8601 format) |
	| **temperature_2m_max (Float)** | Max Temperature | Maximum air temperature at 2 meters above ground in °C |
	| **temperature_2m_min (Float)** | Min Temperature | Minimum air temperature at 2 meters above ground in °C |
	| **temperature_2m_mean (Float)** | Mean Temperature | Average air temperature at 2 meters above ground in °C |
	| **apparent_temperature_max (Float)** | Max Feels Like | Maximum apparent temperature (feels like) in °C |
	| **apparent_temperature_min (Float)** | Min Feels Like | Minimum apparent temperature (feels like) in °C |
	| **apparent_temperature_mean (Float)** | Mean Feels Like | Average apparent temperature (feels like) in °C |
	| **precipitation_sum (Float)** | Daily Precipitation | Total daily precipitation (rain, showers, snow) in mm |
	| **rain_sum (Float)**    | Daily Rain           | Total daily rain precipitation in mm |
	| **snowfall_sum (Float)** | Daily Snowfall      | Total daily snowfall amount in cm |
	| **snow_depth_max (Float)** | Snow Depth        | Maximum daily snow depth in cm |
	| **wind_speed_10m_max (Float)** | Max Wind Speed | Maximum wind speed at 10 meters above ground in km/h |
	| **wind_gusts_10m_max (Float)** | Max Wind Gusts | Maximum wind gusts at 10 meters above ground in km/h |
	| **wind_direction_10m_dominant (Integer)** | Wind Direction | Dominant wind direction at 10 meters in degrees |
	| **cloud_cover_mean (Integer)** | Cloud Cover     | Mean total cloud cover percentage (0-100%) |
	| **relative_humidity_2m_max (Integer)** | Max Humidity | Maximum relative humidity at 2 meters in % |
	| **relative_humidity_2m_min (Integer)** | Min Humidity | Minimum relative humidity at 2 meters in % |
	| **relative_humidity_2m_mean (Integer)** | Mean Humidity | Average relative humidity at 2 meters in % |
	
	### **Last updated:**
	
	Historical data available from 1940 through current date
	
	### **Next update:**
	
	Daily updates with approximately 5-day delay for final quality-controlled data
	
	### **Data source(s)**
	
	- Open-Meteo Weather API
	- Based on NOAA, ECMWF, and national weather service data
	
	### **URLs to dataset**
	
	- API Endpoint: https://archive-api.open-meteo.com/v1/archive
	- Example Request for Chicago: 
	  ```
	  https://archive-api.open-meteo.com/v1/archive?latitude=41.8781&longitude=-87.6298&start_date=2023-01-01&end_date=2023-12-31&daily=temperature_2m_max,temperature_2m_min,precipitation_sum&timezone=America%2FChicago
	  ```
	
	### **License**
	
	Open-Meteo data is available under the [Creative Commons Attribution 4.0 International License (CC BY 4.0)](https://creativecommons.org/licenses/by/4.0/). The data is provided for free for both commercial and non-commercial use, with attribution to Open-Meteo required.
	
	</details>

## Integrated Analysis Insights

Based on comprehensive exploratory data analysis (EDA) and integrated analysis across all datasets, key insights include:

### **Cross-Dataset Integration**
- **Station Matching**: Successfully integrated 1,018 stations using station names (not IDs) due to different ID formats between trip and GBFS data
- **Weather-Trip Correlation**: Strong statistical correlation (p=0.0486) between weather conditions and ridership patterns
- **Data Quality**: High completeness across all datasets with successful data pipeline integration

### **Usage Patterns**
- **Peak Performance**: Clinton St & Washington Blvd is the busiest station with 3,051 trips per month
- **User Behavior**: Members (83.1%) show consistent usage patterns; Casual riders (16.9%) are more weather-sensitive
- **Seasonal Impact**: Winter usage demonstrates resilience with 140,208 trips in January 2024
- **Station Utilization**: Wide variation from empty stations to 100% utilization, average 24.2%

### **Weather Impact Discovery**
- **Surprising Finding**: Light rain actually increases usage contrary to expectations
- **Temperature Sensitivity**: Casual riders 1.4x more sensitive to temperature changes than members
- **Optimal Conditions**: Cold temperatures with light precipitation show highest ridership
- **Business Application**: Weather forecasting can predict demand with 70%+ accuracy

### **Geographic Distribution**
- **Network Scope**: 46.2 km (N-S) × 26.8 km (E-W) coverage across Chicago metropolitan area
- **Capacity Planning**: Station capacity ranges 1-120 docks, average 11.0 per station
- **Strategic Locations**: High-traffic stations concentrated in business and university districts
- **Integration Success**: Station name-based matching enabled comprehensive spatial analysis

## Data Modeling Approach

The Entity Relational Diagram (ERD):

<center>

![ERD](images/Entity-Relational-Diagram-(ERD)-Divvybikes.svg)

</center>

## Tech Stacks and Architecture

## Divvy Dashboard

## Getting Started

### Prerequisites
- AWS CLI configured with appropriate credentials
- Docker and Docker Compose
- Terraform >= 1.0
- Git

### Environment Setup

⚠️ **Important**: This project uses environment variables for all sensitive configuration. Never commit `.env` files or hardcoded credentials.

1. **Configure environment variables**:
   ```bash
   # Copy templates
   cp .env.template .env
   cd airflow && cp .env.template .env
   
   # Edit both .env files with your secure passwords and configuration
   ```

2. **Set up infrastructure**:
   ```bash
   cd terraform
   source load_env.sh  # Load environment variables
   make deploy-all     # Deploy AWS infrastructure
   ```

3. **Start Airflow**:
   ```bash
   cd airflow
   ./start_airflow.sh  # Starts Docker-based Airflow
   ```

📚 **Detailed Setup Guide**: See [docs/environment-setup.md](docs/environment-setup.md) for comprehensive instructions.

## Contributions and Feedback

## License

This project is licensed under the Apache 2.0 License. See the [LICENSE](LICENSE) file for details.