# Divvy Bikes Comprehensive Data Analysis Suite
## 5 Business Questions - 20 Strategic Analyses

### Overview
This comprehensive analysis suite contains 20 SQL queries designed to answer 5 critical business questions about converting casual riders to annual members. Each analysis provides actionable insights for data-driven marketing strategies and operational optimization.

### Business Questions Addressed

## Business Question 1: User Behavior Differences
**"How do annual members and casual riders use Divvy bikes differently?"**

### Analysis Files

#### 1. Trip Duration Analysis (`1_trip_duration_analysis.sql`)
**Objective**: Trip duration distribution analysis comparing members vs casual riders
- **Key Insights**: Short/medium/long/extra-long ride categories with YoY growth patterns
- **Output**: `1_trip_duration_analysis.csv` - Duration category distributions with conversion metrics
- **Marketing Applications**: 
  - Target long-duration casual riders with "unlimited rides" messaging
  - Focus on medium-duration users with convenience benefits
  - Create duration-based membership tiers

#### 2. Temporal Usage Patterns (`2_temporal_usage_patterns.sql`) 
**Objective**: Daily, weekly, and hourly usage pattern analysis
- **Key Insights**: Peak hours, weekday vs weekend preferences, seasonal trends by user type
- **Output**: `2_temporal_usage_patterns.csv` - Temporal pattern analysis with peak usage identification
- **Marketing Applications**:
  - Time-targeted digital advertising campaigns
  - Commuter-focused weekday messaging for casual riders
  - Weekend recreational membership packages

#### 3. Station and Route Analysis (`3_station_route_analysis.sql`)
**Objective**: Popular routes and station analysis with conversion targets
- **Key Insights**: Top point-to-point routes, station usage rankings by user type
- **Outputs**: 
  - `3_station_route_analysis_main.csv` - Station and route popularity rankings
  - `3_station_route_type_analysis.csv` - Point-to-point vs round trip behavior analysis
- **Marketing Applications**:
  - Deploy targeted station advertising at high casual-usage locations  
  - Geofenced digital campaigns near conversion-potential stations
  - Route-specific promotional campaigns

#### 4. Bike Type & Behavioral Analysis (`4_bike_type_behavioral_analysis.sql`)
**Objective**: Bike type preferences with usage intensity categorization
- **Key Insights**: Classic, e-bike, e-scooter preferences with seasonal behavioral patterns
- **Outputs**:
  - `4_bike_type_behavioral_analysis_main.csv` - Bike type preferences with seasonal patterns
  - `4_bike_type_seasonal_analysis.csv` - Seasonal bike type usage analysis
- **Marketing Applications**:
  - Bike-type-specific membership messaging
  - Target "power users" among casual riders
  - Behavioral similarity-based conversion campaigns

## Business Question 2: Conversion Potential Indicators
**"What factors indicate high conversion potential from casual riders to members?"**

#### 5. Usage Frequency Conversion Analysis (`5_usage_frequency_conversion_analysis.sql`)
**Objective**: Usage frequency threshold analysis identifying financial break-even points
- **Key Insights**: Conversion scoring based on trip volume patterns
- **Output**: `5_usage_frequency_conversion_analysis.csv` - Financial threshold and conversion scoring
- **Marketing Applications**:
  - Target users approaching break-even thresholds
  - Personalized ROI messaging based on usage patterns
  - Frequency-based campaign triggers

#### 6. Behavioral Similarity Analysis (`6_behavioral_similarity_analysis.sql`)
**Objective**: Behavioral similarity scoring comparing casual riders to existing members
- **Key Insights**: 6-factor analysis (duration, timing, geographic patterns)
- **Output**: `6_behavioral_similarity_analysis.csv` - Member-like behavior identification
- **Marketing Applications**:
  - Target "member-like" casual riders with tailored messaging
  - Similarity-based segmentation for campaigns
  - Behavioral prediction modeling

#### 7. Temporal Conversion Patterns (`7_temporal_conversion_patterns.sql`)
**Objective**: Temporal conversion lifecycle analysis
- **Key Insights**: Optimal conversion windows based on user tenure and trip accumulation
- **Output**: `7_temporal_conversion_patterns.csv` - Lifecycle and tenure-based conversion patterns
- **Marketing Applications**:
  - Time-based conversion campaign deployment
  - Lifecycle stage targeting
  - Optimal engagement timing strategies

#### 8. Geographic Conversion Hotspots (`8_geographic_conversion_hotspots.sql`)
**Objective**: Geographic conversion opportunities with penetration gap analysis
- **Key Insights**: Station-level revenue impact calculations
- **Output**: `8_geographic_conversion_hotspots.csv` - Geographic opportunity mapping
- **Marketing Applications**:
  - Location-based conversion campaigns
  - Geographic expansion prioritization
  - Station-specific promotional strategies

## Business Question 3: Campaign Timing and Targeting
**"When and how should we target casual riders for maximum conversion impact?"**

#### 9. Seasonal Campaign Windows (`9_seasonal_campaign_windows.sql`)
**Objective**: Seasonal campaign optimization with annual calendar planning
- **Key Insights**: Budget allocation and YoY growth projections for 2025 strategy
- **Output**: `9_seasonal_campaign_windows.csv` - Annual campaign calendar with budget recommendations
- **Marketing Applications**:
  - Annual marketing budget allocation
  - Seasonal campaign planning
  - Weather-based strategy optimization

#### 10. Daily Hourly Targeting (`10_daily_hourly_targeting.sql`)
**Objective**: Real-time engagement window analysis
- **Key Insights**: Hour-by-hour conversion scoring and optimal messaging timing
- **Output**: `10_daily_hourly_targeting.csv` - Hourly engagement optimization
- **Marketing Applications**:
  - Real-time campaign deployment
  - Time-of-day targeting optimization
  - Dynamic content scheduling

#### 11. Station ROI Prioritization (`11_station_roi_prioritization.sql`)
**Objective**: Station-based marketing ROI analysis
- **Key Insights**: Investment tier prioritization and tactical deployment recommendations
- **Output**: `11_station_roi_prioritization.csv` - Station-level ROI and investment prioritization
- **Marketing Applications**:
  - Physical advertising placement decisions
  - Station investment prioritization
  - Location-based ROI optimization

#### 12. Usage Trigger Personalization (`12_usage_trigger_personalization.sql`)
**Objective**: Usage-based trigger point analysis for automated campaign deployment
- **Key Insights**: Behavioral milestone identification and personalization rules
- **Output**: `12_usage_trigger_personalization.csv` - Behavioral trigger automation rules
- **Marketing Applications**:
  - Automated campaign triggers
  - Personalized messaging deployment
  - Behavioral milestone marketing

## Business Question 4: Weather Impact Analysis
**"How does weather affect different user types and conversion potential?"**

#### 13. Temperature Elasticity Analysis (`13_temperature_elasticity_analysis.sql`)
**Objective**: Temperature sensitivity analysis by user type
- **Key Insights**: Conversion opportunity scoring based on weather resilience patterns
- **Output**: `13_temperature_elasticity_analysis.csv` - Temperature-based conversion opportunities
- **Marketing Applications**:
  - Weather-based campaign timing
  - Temperature-sensitive messaging
  - Seasonal conversion strategies

#### 14. Precipitation Impact Analysis (`14_precipitation_impact_analysis.sql`)
**Objective**: Precipitation impact assessment on ridership
- **Key Insights**: Duration, frequency, and user behavior resilience across weather conditions
- **Output**: `14_precipitation_impact_analysis.csv` - Weather resilience assessment
- **Marketing Applications**:
  - Weather-resistant user identification
  - Rainy season campaign strategies
  - Weather-based user segmentation

#### 15. Seasonal Weather Conversion (`15_seasonal_weather_conversion.sql`)
**Objective**: Seasonal weather effects on conversion potential
- **Key Insights**: Weather-optimized campaign timing and budget allocation strategies
- **Output**: `15_seasonal_weather_conversion.csv` - Weather-optimized campaign timing
- **Marketing Applications**:
  - Seasonal weather marketing
  - Climate-based campaign optimization
  - Weather-adjusted targeting

#### 16. Extreme Weather Recovery (`16_extreme_weather_recovery.sql`)
**Objective**: Extreme weather event recovery pattern analysis
- **Key Insights**: Weather-resilient riders and post-event re-engagement opportunities
- **Output**: `16_extreme_weather_recovery.csv` - Weather event recovery patterns
- **Marketing Applications**:
  - Post-weather event campaigns
  - Resilient user targeting
  - Recovery period optimization

## Business Question 5: Geographic Conversion Potential
**"Which stations and neighborhoods show highest conversion potential?"**

#### 17. High Potential Station Conversion (`17_high_potential_station_conversion.sql`)
**Objective**: High-potential station identification with casual usage concentration analysis
- **Key Insights**: Station-specific conversion campaign recommendations
- **Output**: `17_high_potential_station_conversion.csv` - Station-specific conversion targets
- **Marketing Applications**:
  - Station-level conversion campaigns
  - High-potential location targeting
  - Geographic conversion optimization

#### 18. Route Commuter Potential Analysis (`18_route_commuter_potential_analysis.sql`)
**Objective**: Route-based commuter potential analysis
- **Key Insights**: Casual riders with member-like commuting patterns and route-specific targeting
- **Output**: `18_route_commuter_potential_analysis.csv` - Route-based commuter identification
- **Marketing Applications**:
  - Commuter-focused conversion campaigns
  - Route-specific targeting
  - Transportation alternative messaging

#### 19. Station Pair Traffic Analysis (`19_station_pair_traffic_analysis.sql`)
**Objective**: Station pair traffic corridor analysis
- **Key Insights**: High-casual volume route identification and corridor-level marketing prioritization
- **Output**: `19_station_pair_traffic_analysis.csv` - Corridor traffic and conversion analysis
- **Marketing Applications**:
  - Corridor-based marketing campaigns
  - Route-specific advertising
  - Traffic pattern optimization

#### 20. Neighborhood Conversion Characteristics (`20_neighborhood_conversion_characteristics.sql`)
**Objective**: Neighborhood-level conversion characteristics analysis
- **Key Insights**: Geographic clustering, penetration gap assessment, and area-wide targeting strategies
- **Output**: `20_neighborhood_conversion_characteristics.csv` - Neighborhood-level targeting opportunities
- **Marketing Applications**:
  - Neighborhood-specific campaigns
  - Area-wide conversion strategies
  - Geographic expansion planning

### Data Sources
- **Primary**: `"divvy"."public_gold"."trips_enhanced"` - Complete trip data with enrichments
- **Secondary**: `"divvy"."public_gold"."behavioral_analysis"` - Daily aggregated patterns
- **Weather**: `"divvy"."public_silver"."weather_cleaned"` - Weather impact analysis
- **Stations**: `"divvy"."public_silver"."stations_enhanced"` - Station metadata and analytics
- **Time Period**: 24-month dataset (2023-2024) with focus on 2024 and YoY comparisons

### How to Execute
1. Connect to Redshift using the credentials in `.env`
2. Run each analysis file independently in Redshift Query Editor v2
3. Export results to `data/gold/` directory for visualization and marketing strategy development
4. Use results in dashboard applications and marketing automation tools

### Expected Marketing Outcomes
- **Segmentation**: 15+ distinct casual rider segments for targeted conversion
- **Timing**: Optimal times, seasons, and lifecycle stages for conversion campaigns  
- **Messaging**: Behavior-based messaging strategies for different casual rider types
- **Channels**: Location, time, and weather-based channel optimization for maximum conversion impact
- **ROI**: Station-level and geographic ROI optimization for marketing investments

### Key Performance Indicators (KPIs) to Track
- Conversion rate by segment type (target: 15-25% improvement)
- Campaign engagement by temporal targeting (target: 30% higher engagement)
- Station-based conversion performance (target: identify top 100 priority stations)
- Weather-adjusted conversion rates (target: 20% improvement in weather-resistant messaging)
- Geographic penetration improvements (target: identify 50+ high-opportunity neighborhoods)

### Files Location
```
dbt_divvy/analyses/
├── Business Question 1: User Behavior Differences
│   ├── 1_trip_duration_analysis.sql
│   ├── 2_temporal_usage_patterns.sql
│   ├── 3_station_route_analysis.sql
│   └── 4_bike_type_behavioral_analysis.sql
├── Business Question 2: Conversion Potential Indicators  
│   ├── 5_usage_frequency_conversion_analysis.sql
│   ├── 6_behavioral_similarity_analysis.sql
│   ├── 7_temporal_conversion_patterns.sql
│   └── 8_geographic_conversion_hotspots.sql
├── Business Question 3: Campaign Timing and Targeting
│   ├── 9_seasonal_campaign_windows.sql
│   ├── 10_daily_hourly_targeting.sql
│   ├── 11_station_roi_prioritization.sql
│   └── 12_usage_trigger_personalization.sql
├── Business Question 4: Weather Impact Analysis
│   ├── 13_temperature_elasticity_analysis.sql
│   ├── 14_precipitation_impact_analysis.sql
│   ├── 15_seasonal_weather_conversion.sql
│   └── 16_extreme_weather_recovery.sql
└── Business Question 5: Geographic Conversion Potential
    ├── 17_high_potential_station_conversion.sql
    ├── 18_route_commuter_potential_analysis.sql
    ├── 19_station_pair_traffic_analysis.sql
    └── 20_neighborhood_conversion_characteristics.sql
```

### Results Location
```
data/gold/
├── Business Question 1 Results
│   ├── 1_trip_duration_analysis.csv
│   ├── 2_temporal_usage_patterns.csv
│   ├── 3_station_route_analysis_main.csv
│   ├── 3_station_route_type_analysis.csv
│   ├── 4_bike_type_behavioral_analysis_main.csv
│   └── 4_bike_type_seasonal_analysis.csv
├── Business Question 2 Results
│   ├── 5_usage_frequency_conversion_analysis.csv
│   ├── 6_behavioral_similarity_analysis.csv
│   ├── 7_temporal_conversion_patterns.csv
│   └── 8_geographic_conversion_hotspots.csv
├── Business Question 3 Results
│   ├── 9_seasonal_campaign_windows.csv
│   ├── 10_daily_hourly_targeting.csv
│   ├── 11_station_roi_prioritization.csv
│   └── 12_usage_trigger_personalization.csv
├── Business Question 4 Results
│   ├── 13_temperature_elasticity_analysis.csv
│   ├── 14_precipitation_impact_analysis.csv
│   ├── 15_seasonal_weather_conversion.csv
│   └── 16_extreme_weather_recovery.csv
└── Business Question 5 Results
    ├── 17_high_potential_station_conversion.csv
    ├── 18_route_commuter_potential_analysis.csv
    ├── 19_station_pair_traffic_analysis.csv
    └── 20_neighborhood_conversion_characteristics.csv
```

Each analysis file contains detailed commentary on expected insights and specific marketing actions that can be taken based on the analysis results. The comprehensive suite enables data-driven decision making for converting casual riders to annual members through targeted, personalized, and optimally-timed marketing campaigns.
