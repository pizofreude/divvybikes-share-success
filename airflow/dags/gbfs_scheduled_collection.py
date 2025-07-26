"""
GBFS Scheduled Data Collection Configuration
===========================================

Configuration file for scheduled GBFS data collection.
This file defines the schedule intervals and collection strategies.

Recommended Schedules:
- Station Information: Daily at 6:00 AM (data changes infrequently)
- Station Status: Every 2 hours (for trend analysis)

To implement scheduling:
1. Modify the main gbfs_data_ingestion.py DAG
2. Set appropriate schedule_interval values
3. Deploy to Airflow

Author: Analytics Engineering Team
Created: July 2025
"""

from datetime import datetime, timedelta

# Schedule Configuration
GBFS_SCHEDULES = {
    "station_information": {
        "schedule_interval": "0 6 * * *",  # Daily at 6:00 AM
        "description": "Daily collection of static station metadata",
        "max_active_runs": 1,
        "retries": 3,
        "retry_delay": timedelta(minutes=10)
    },
    "station_status": {
        "schedule_interval": "0 */2 * * *",  # Every 2 hours
        "description": "Bi-hourly collection of real-time station status",
        "max_active_runs": 1,
        "retries": 2,
        "retry_delay": timedelta(minutes=5)
    },
    "system_information": {
        "schedule_interval": "0 12 * * *",  # Daily at noon
        "description": "Daily collection of system metadata",
        "max_active_runs": 1,
        "retries": 2,
        "retry_delay": timedelta(minutes=5)
    }
}

# Default DAG Arguments for scheduled collections
SCHEDULED_DEFAULT_ARGS = {
    "owner": "analytics-team",
    "depends_on_past": False,
    "start_date": datetime(2025, 7, 27),
    "email_on_failure": True,
    "email": ["data-alerts@company.com"],  # Update with actual email
    "email_on_retry": False,
    "catchup": False,
}

# Collection Strategy Documentation
COLLECTION_STRATEGY = """
GBFS Data Collection Strategy:

1. Station Information (Daily):
   - Static metadata that rarely changes
   - Cost-efficient daily collection
   - Used for dimension table updates

2. Station Status (Every 2 hours):
   - Real-time availability and operational status
   - Provides trend analysis without excessive API calls
   - Balances data freshness with cost

3. Implementation Notes:
   - Use separate DAG instances or conditional logic
   - Monitor API rate limits and costs
   - Implement data quality validation
   - Set up alerting for collection failures

4. Future Enhancements:
   - Dynamic scheduling based on operational needs
   - Weekend/holiday schedule adjustments
   - Integration with demand forecasting models
"""

# Usage Instructions
USAGE_INSTRUCTIONS = """
To implement scheduled collection:

1. Update main DAG schedule_interval:
   ```python
   dag = DAG(
       "gbfs_data_ingestion",
       schedule_interval=GBFS_SCHEDULES["station_status"]["schedule_interval"],
       # ... other parameters
   )
   ```

2. Create endpoint-specific DAGs:
   - gbfs_station_info_daily.py
   - gbfs_station_status_hourly.py

3. Deploy and monitor:
   - Test in development environment
   - Monitor logs and data quality
   - Set up alerting for failures
"""
