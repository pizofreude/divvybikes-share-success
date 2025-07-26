"""
Simple test script to debug weather API issues in Airflow
"""

from datetime import datetime
import requests
import pandas as pd
from airflow.models import Variable
from airflow.providers.amazon.aws.hooks.s3 import S3Hook

def test_weather_api_simple():
    """Test a simple weather API call."""
    try:
        print("🌤️  Testing weather API...")
        
        # Test API call
        params = {
            'latitude': 41.8781,
            'longitude': -87.6298,
            'start_date': '2023-01-01',
            'end_date': '2023-01-03',
            'daily': 'temperature_2m_max,temperature_2m_min,precipitation_sum',
            'timezone': 'America/Chicago'
        }
        
        response = requests.get('https://archive-api.open-meteo.com/v1/archive', params=params, timeout=30)
        response.raise_for_status()
        
        data = response.json()
        print(f"✅ API call successful - received {len(data['daily']['time'])} days")
        
        # Test S3 access
        s3_hook = S3Hook(aws_conn_id='aws_default')
        bronze_bucket = Variable.get("bronze_bucket", "divvybikes-dev-bronze-96wb3c9c")
        
        if s3_hook.check_for_bucket(bronze_bucket):
            print(f"✅ S3 bucket access successful: {bronze_bucket}")
        else:
            print(f"❌ S3 bucket access failed: {bronze_bucket}")
            
        # Test data processing
        df = pd.DataFrame(data['daily'])
        print(f"✅ DataFrame created: {df.shape}")
        
        return True
        
    except Exception as e:
        print(f"❌ Test failed: {str(e)}")
        return False

if __name__ == "__main__":
    test_weather_api_simple()
