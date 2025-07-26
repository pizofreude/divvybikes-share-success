"""
GBFS API Test Script
===================

Test script for validating GBFS API connectivity and data structure
before deploying the Airflow DAG.

Usage:
    python test_gbfs_api.py

This script tests:
1. GBFS API endpoint accessibility
2. Data structure validation
3. Data quality checks
4. Sample data processing

Author: Analytics Engineering Team
Created: July 2025
"""

import json
import requests
import pandas as pd
from datetime import datetime
from typing import Dict, Any, List
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# GBFS API Configuration
GBFS_BASE_URL = "https://gbfs.lyft.com/gbfs/2.3/chi/en"
GBFS_ENDPOINTS = {
    "station_information": f"{GBFS_BASE_URL}/station_information.json",
    "station_status": f"{GBFS_BASE_URL}/station_status.json",
    "system_information": f"{GBFS_BASE_URL}/system_information.json",
    "free_bike_status": f"{GBFS_BASE_URL}/free_bike_status.json"
}

def test_gbfs_endpoint(endpoint_name: str, url: str) -> Dict[str, Any]:
    """
    Test a single GBFS endpoint for connectivity and data structure.
    
    Args:
        endpoint_name: Name of the endpoint
        url: Endpoint URL
        
    Returns:
        Test results dictionary
    """
    logger.info(f"Testing {endpoint_name} endpoint...")
    
    test_result = {
        "endpoint_name": endpoint_name,
        "url": url,
        "test_timestamp": datetime.now().isoformat(),
        "connection_success": False,
        "response_time_ms": 0,
        "data_structure_valid": False,
        "record_count": 0,
        "data_quality_issues": [],
        "sample_data": None
    }
    
    try:
        # Test API connectivity
        start_time = datetime.now()
        response = requests.get(url, timeout=30)
        response.raise_for_status()
        end_time = datetime.now()
        
        test_result["connection_success"] = True
        test_result["response_time_ms"] = int((end_time - start_time).total_seconds() * 1000)
        
        # Parse JSON response
        data = response.json()
        
        # Validate GBFS structure
        if 'data' in data and 'last_updated' in data:
            test_result["data_structure_valid"] = True
            
            # Extract relevant data based on endpoint
            if endpoint_name == "station_information" and 'stations' in data['data']:
                stations = data['data']['stations']
                test_result["record_count"] = len(stations)
                test_result["sample_data"] = stations[:3] if stations else []
                
                # Data quality checks for station information
                for i, station in enumerate(stations[:100]):  # Check first 100 stations
                    if not station.get('station_id'):
                        test_result["data_quality_issues"].append(f"Station {i}: Missing station_id")
                    if not station.get('name'):
                        test_result["data_quality_issues"].append(f"Station {i}: Missing name")
                    if station.get('lat') is None or station.get('lon') is None:
                        test_result["data_quality_issues"].append(f"Station {i}: Missing coordinates")
                    if station.get('capacity') is None:
                        test_result["data_quality_issues"].append(f"Station {i}: Missing capacity")
                        
            elif endpoint_name == "station_status" and 'stations' in data['data']:
                stations = data['data']['stations']
                test_result["record_count"] = len(stations)
                test_result["sample_data"] = stations[:3] if stations else []
                
                # Data quality checks for station status
                total_bikes = 0
                total_docks = 0
                operational_stations = 0
                
                for i, station in enumerate(stations):
                    if not station.get('station_id'):
                        test_result["data_quality_issues"].append(f"Station {i}: Missing station_id")
                    
                    # Calculate totals
                    total_bikes += station.get('num_bikes_available', 0)
                    total_docks += station.get('num_docks_available', 0)
                    
                    if station.get('is_installed') and station.get('is_renting'):
                        operational_stations += 1
                
                # Add summary statistics
                test_result["summary_stats"] = {
                    "total_bikes_available": total_bikes,
                    "total_docks_available": total_docks,
                    "operational_stations": operational_stations,
                    "total_stations": len(stations)
                }
                
            elif endpoint_name == "system_information":
                test_result["sample_data"] = data['data']
                
            elif endpoint_name == "free_bike_status" and 'bikes' in data['data']:
                bikes = data['data']['bikes']
                test_result["record_count"] = len(bikes)
                test_result["sample_data"] = bikes[:3] if bikes else []
        
        logger.info(f"✅ {endpoint_name}: {test_result['record_count']} records, "
                   f"{test_result['response_time_ms']}ms response time")
        
        if test_result["data_quality_issues"]:
            logger.warning(f"⚠️  {endpoint_name}: {len(test_result['data_quality_issues'])} data quality issues found")
        
    except requests.exceptions.RequestException as e:
        logger.error(f"❌ {endpoint_name}: Connection error - {str(e)}")
        test_result["error"] = str(e)
    except json.JSONDecodeError as e:
        logger.error(f"❌ {endpoint_name}: JSON decode error - {str(e)}")
        test_result["error"] = str(e)
    except Exception as e:
        logger.error(f"❌ {endpoint_name}: Unexpected error - {str(e)}")
        test_result["error"] = str(e)
    
    return test_result

def analyze_station_data_structure():
    """
    Analyze the structure of station information and status data.
    """
    logger.info("Analyzing GBFS data structure...")
    
    try:
        # Fetch station information
        info_response = requests.get(GBFS_ENDPOINTS["station_information"], timeout=30)
        info_data = info_response.json()
        
        # Fetch station status
        status_response = requests.get(GBFS_ENDPOINTS["station_status"], timeout=30)
        status_data = status_response.json()
        
        if 'data' in info_data and 'stations' in info_data['data']:
            stations_info = info_data['data']['stations']
            logger.info(f"Station Information: {len(stations_info)} stations")
            
            # Analyze station info structure
            if stations_info:
                sample_station = stations_info[0]
                logger.info("Station Information Fields:")
                for key, value in sample_station.items():
                    logger.info(f"  - {key}: {type(value).__name__} = {value}")
        
        if 'data' in status_data and 'stations' in status_data['data']:
            stations_status = status_data['data']['stations']
            logger.info(f"Station Status: {len(stations_status)} stations")
            
            # Analyze station status structure
            if stations_status:
                sample_status = stations_status[0]
                logger.info("Station Status Fields:")
                for key, value in sample_status.items():
                    logger.info(f"  - {key}: {type(value).__name__} = {value}")
        
        # Cross-reference station IDs
        if 'data' in info_data and 'data' in status_data:
            info_station_ids = {s['station_id'] for s in info_data['data']['stations']}
            status_station_ids = {s['station_id'] for s in status_data['data']['stations']}
            
            logger.info(f"Station ID Analysis:")
            logger.info(f"  - Info stations: {len(info_station_ids)}")
            logger.info(f"  - Status stations: {len(status_station_ids)}")
            logger.info(f"  - Common stations: {len(info_station_ids & status_station_ids)}")
            logger.info(f"  - Info only: {len(info_station_ids - status_station_ids)}")
            logger.info(f"  - Status only: {len(status_station_ids - info_station_ids)}")
            
    except Exception as e:
        logger.error(f"Error analyzing data structure: {str(e)}")

def test_data_processing():
    """
    Test the data processing functions that will be used in the DAG.
    """
    logger.info("Testing data processing functions...")
    
    try:
        # Fetch station status for processing test
        response = requests.get(GBFS_ENDPOINTS["station_status"], timeout=30)
        data = response.json()
        
        if 'data' in data and 'stations' in data['data']:
            stations = data['data']['stations']
            
            # Process like the DAG would
            processed_stations = []
            for station in stations:
                total_capacity = (station.get('num_bikes_available', 0) + 
                                station.get('num_bikes_disabled', 0) + 
                                station.get('num_docks_available', 0) + 
                                station.get('num_docks_disabled', 0))
                
                utilization_rate = 0
                if total_capacity > 0:
                    bikes_present = station.get('num_bikes_available', 0) + station.get('num_bikes_disabled', 0)
                    utilization_rate = round((bikes_present / total_capacity) * 100, 2)
                
                processed_station = {
                    "station_id": station.get('station_id'),
                    "num_bikes_available": station.get('num_bikes_available', 0),
                    "num_docks_available": station.get('num_docks_available', 0),
                    "total_capacity": total_capacity,
                    "utilization_rate": utilization_rate,
                    "is_operational": station.get('is_installed', False) and station.get('is_renting', False)
                }
                processed_stations.append(processed_station)
            
            # Convert to DataFrame for analysis
            df = pd.DataFrame(processed_stations)
            
            logger.info("Processing Test Results:")
            logger.info(f"  - Total stations processed: {len(df)}")
            logger.info(f"  - Operational stations: {df['is_operational'].sum()}")
            logger.info(f"  - Total bikes available: {df['num_bikes_available'].sum()}")
            logger.info(f"  - Total docks available: {df['num_docks_available'].sum()}")
            logger.info(f"  - Average utilization: {df['utilization_rate'].mean():.2f}%")
            logger.info(f"  - Max utilization: {df['utilization_rate'].max():.2f}%")
            logger.info(f"  - Stations with 0% utilization: {(df['utilization_rate'] == 0).sum()}")
            logger.info(f"  - Stations with 100% utilization: {(df['utilization_rate'] == 100).sum()}")
            
    except Exception as e:
        logger.error(f"Error in data processing test: {str(e)}")

def generate_test_report(test_results: List[Dict[str, Any]]) -> None:
    """
    Generate a comprehensive test report.
    
    Args:
        test_results: List of test results from each endpoint
    """
    logger.info("=" * 80)
    logger.info("GBFS API TEST REPORT")
    logger.info("=" * 80)
    
    total_endpoints = len(test_results)
    successful_connections = sum(1 for r in test_results if r["connection_success"])
    valid_structures = sum(1 for r in test_results if r["data_structure_valid"])
    
    logger.info(f"Overall Results:")
    logger.info(f"  - Total endpoints tested: {total_endpoints}")
    logger.info(f"  - Successful connections: {successful_connections}/{total_endpoints}")
    logger.info(f"  - Valid data structures: {valid_structures}/{total_endpoints}")
    
    logger.info(f"\nDetailed Results:")
    for result in test_results:
        status_icon = "✅" if result["connection_success"] and result["data_structure_valid"] else "❌"
        logger.info(f"  {status_icon} {result['endpoint_name']}")
        logger.info(f"    - URL: {result['url']}")
        logger.info(f"    - Response time: {result['response_time_ms']}ms")
        logger.info(f"    - Record count: {result['record_count']}")
        
        if result.get("summary_stats"):
            stats = result["summary_stats"]
            logger.info(f"    - Summary: {stats}")
        
        if result["data_quality_issues"]:
            logger.info(f"    - Quality issues: {len(result['data_quality_issues'])}")
            for issue in result["data_quality_issues"][:5]:  # Show first 5 issues
                logger.info(f"      • {issue}")
        
        if result.get("error"):
            logger.info(f"    - Error: {result['error']}")
        
        logger.info("")
    
    # Recommendations
    logger.info("Recommendations:")
    if successful_connections == total_endpoints:
        logger.info("  ✅ All endpoints are accessible - ready for DAG deployment")
    else:
        logger.info("  ⚠️  Some endpoints failed - investigate before deploying DAG")
    
    if any(r["data_quality_issues"] for r in test_results):
        logger.info("  ⚠️  Data quality issues detected - implement validation in DAG")
    else:
        logger.info("  ✅ No major data quality issues detected")
    
    # Priority endpoints for initial implementation
    priority_endpoints = ['station_information', 'station_status']
    priority_results = [r for r in test_results if r["endpoint_name"] in priority_endpoints]
    
    if all(r["connection_success"] and r["data_structure_valid"] for r in priority_results):
        logger.info("  ✅ Priority endpoints (station_information, station_status) are ready")
        logger.info("  📋 Recommended next steps:")
        logger.info("     1. Deploy GBFS DAG with station_information and station_status")
        logger.info("     2. Set up monitoring and alerting")
        logger.info("     3. Test Silver layer data processing")
        logger.info("     4. Consider adding free_bike_status endpoint later")
    else:
        logger.info("  ⚠️  Priority endpoints have issues - resolve before deployment")

def main():
    """
    Main test execution function.
    """
    logger.info("Starting GBFS API Testing...")
    logger.info(f"Test timestamp: {datetime.now().isoformat()}")
    logger.info(f"Base URL: {GBFS_BASE_URL}")
    
    # Test all endpoints
    test_results = []
    for endpoint_name, url in GBFS_ENDPOINTS.items():
        result = test_gbfs_endpoint(endpoint_name, url)
        test_results.append(result)
    
    # Analyze data structure
    analyze_station_data_structure()
    
    # Test data processing
    test_data_processing()
    
    # Generate comprehensive report
    generate_test_report(test_results)
    
    logger.info("GBFS API testing completed!")

if __name__ == "__main__":
    main()
