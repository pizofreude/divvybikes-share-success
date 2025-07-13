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
	| **capacity (Integer)**  | Capacity               | Total number of docks at the station |
	| **rental_methods (Array)** | Rental Methods      | Available methods for renting bikes (key, creditcard, etc.) |
	| **has_kiosk (Boolean)** | Has Kiosk              | Whether the station has a payment kiosk |
	| **electric_bike_surcharge_waiver (Boolean)** | E-Bike Surcharge Waiver | Whether e-bike surcharges are waived at this station |
	| **station_type (String)** | Station Type         | Classification of station (classic, electric, smart) |
	| **region_id (String)**  | Region ID              | Identifier for the region in which the station is located |
	
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
	| **temperature_2m (Float)** | Temperature       | Air temperature at 2 meters above ground in °C or °F |
	| **relative_humidity_2m (Integer)** | Relative Humidity | Relative humidity at 2 meters above ground in % |
	| **precipitation (Float)** | Precipitation      | Total precipitation (rain, showers, snow) in mm or inch |
	| **rain (Float)**        | Rain                 | Rain precipitation in mm or inch |
	| **snowfall (Float)**    | Snowfall             | Snowfall amount in cm or inch |
	| **snow_depth (Float)**  | Snow Depth           | Snow depth in meters or feet |
	| **wind_speed_10m (Float)** | Wind Speed        | Wind speed at 10 meters above ground in km/h or mph |
	| **wind_direction_10m (Integer)** | Wind Direction | Wind direction at 10 meters above ground in degrees |
	| **wind_gusts_10m (Float)** | Wind Gusts        | Wind gusts at 10 meters above ground in km/h or mph |
	| **cloud_cover (Integer)** | Cloud Cover        | Total cloud cover in % |
	| **apparent_temperature (Float)** | Feels Like Temperature | Apparent temperature in °C or °F |
	| **is_day (Integer)**    | Daylight             | Binary indicator if the current time step has daylight (1) or night (0) |
	
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

## Data Modeling Approach

The Entity Relational Diagram (ERD):

<center>

![ERD](images/Entity-Relational-Diagram-(ERD)-Divvybikes.svg)

</center>

## Tech Stacks and Architecture

## Divvy Dashboard

## Getting Started

## Contributions and Feedback

## License

This project is licensed under the Apache 2.0 License. See the [LICENSE](LICENSE) file for details.