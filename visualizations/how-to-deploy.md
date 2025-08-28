# Divvy Analytics Dashboard Deployment Guide

## Overview
This guide provides step-by-step instructions for deploying the Divvy Analytics Dashboard to shinyapps.io. The dashboard is built with R Shiny and requires specific setup procedures for successful deployment.

## Prerequisites

### System Requirements
- **R Version:** 4.3.0 or higher
- **RStudio:** Latest version recommended
- **Internet Connection:** Required for package installation and deployment
- **shinyapps.io Account:** Free or paid account

### Required R Packages
The following packages must be installed before deployment:

```r
# Core Shiny packages
install.packages(c(
  "shiny",
  "shinydashboard",
  "shinyWidgets",
  "DT"
))

# Data manipulation and visualization
install.packages(c(
  "dplyr",
  "plotly",
  "ggplot2",
  "scales",
  "viridis"
))

# Deployment package
install.packages("rsconnect")
```

## Pre-Deployment Setup

### 1. Verify Data Files
Ensure all required CSV files are present in the `/deploy/` directory:

```bash
# Check required data files
cd /c/workspace/divvybikes-share-success/deploy
ls -la *.csv
```

**Required Files (13 total):**
- `1_trip_duration_analysis.csv`
- `2_temporal_usage_patterns.csv`
- `4_bike_type_behavioral_analysis_main.csv`
- `5_usage_frequency_conversion_analysis.csv`
- `6_behavioral_similarity_analysis.csv`
- `7_temporal_conversion_patterns.csv`
- `8_geographic_conversion_hotspots.csv`
- `9_seasonal_campaign_windows.csv`
- `10_daily_hourly_targeting.csv`
- `11_station_roi_prioritization.csv`
- `13_temperature_elasticity_analysis.csv`
- `14_precipitation_impact_analysis.csv`
- `17_high_potential_station_conversion.csv`

### 2. Verify Application File
Confirm the main application file is present and functional:
- **File:** `deploy/app.R`
- **Size:** ~28KB
- **Content:** Complete Shiny dashboard application

### 3. Test Locally
Before deploying, test the dashboard locally:

```r
# Navigate to deploy directory
setwd("/c/workspace/divvybikes-share-success/deploy")

# Run the application locally
shiny::runApp("app.R")
```

**Expected Behavior:**
- Dashboard loads without errors
- All 5 tabs are functional
- Charts render properly
- Filters work correctly
- No missing data warnings

## Deployment Process

### Step 1: Configure shinyapps.io Account

1. **Create Account:**
   - Visit [shinyapps.io](https://www.shinyapps.io/)
   - Sign up for free account or upgrade to paid plan
   - Note your account name (e.g., "datafreude")

2. **Get Authentication Token:**
   - Log into shinyapps.io dashboard
   - Go to Account → Tokens
   - Click "Show" next to your token
   - Copy the `rsconnect::setAccountInfo()` command

3. **Configure Local Environment:**
   ```r
   # Install rsconnect if not already installed
   install.packages("rsconnect")
   
   # Configure account (replace with your actual token)
   rsconnect::setAccountInfo(
     name='your-account-name',
     token='your-token-here',
     secret='your-secret-here'
   )
   ```

### Step 2: Prepare for Deployment

1. **Set Working Directory:**
   ```r
   setwd("/c/workspace/divvybikes-share-success/deploy")
   ```

2. **Verify File Structure:**
   ```r
   # List all files that will be deployed
   list.files(pattern = "\\.(R|csv)$", recursive = TRUE)
   ```

3. **Clean Environment:**
   ```r
   # Clear workspace to avoid conflicts
   rm(list = ls())
   ```

### Step 3: Deploy Application

#### Option A: Using R Console
```r
library(rsconnect)

# Deploy with specific app name
rsconnect::deployApp(
  appDir = "/c/workspace/divvybikes-share-success/deploy",
  appName = "Divvy_analytics_dashboard",
  appTitle = "Divvy Bikes Analytics Dashboard",
  account = "your-account-name",
  forceUpdate = TRUE
)
```

#### Option B: Using RStudio Interface
1. Open `deploy/app.R` in RStudio
2. Click "Publish" button in top-right corner
3. Select "Publish Application"
4. Choose shinyapps.io as destination
5. Configure deployment settings:
   - **Title:** "Divvy Bikes Analytics Dashboard"
   - **App Name:** "Divvy_analytics_dashboard" 
   - **Account:** Your account name
6. Include all CSV files in deployment
7. Click "Publish"

### Step 4: Monitor Deployment

1. **Deployment Progress:**
   - Watch console output for progress updates
   - Typical deployment time: 3-5 minutes
   - Monitor for any error messages

2. **Common Deployment Messages:**
   ```
   Preparing to deploy application...
   Uploading bundle for application: XXXXX...
   Deploying bundle: XXXXX for application: XXXXX ...
   Application successfully deployed to https://your-account.shinyapps.io/app-name/
   ```

## Post-Deployment Verification

### 1. Functional Testing
Visit the deployed URL and verify:

- **Dashboard Loads:** No error messages on initial load
- **All Tabs Accessible:** Executive Summary, User Behavior, Conversion Analysis, Geographic Analysis, Weather Impact
- **KPI Value Boxes:** Display correct values (Total Trips, Member Split, YoY Growth, Priority Customers)
- **Interactive Charts:** All 8+ charts render and respond to filters
- **Global Filters:** Year and User Type filters work across all tabs
- **Data Tables:** Sortable and searchable tables function properly

### 2. Performance Testing
- **Load Time:** Dashboard should load within 5-10 seconds
- **Chart Rendering:** Interactive charts should render within 3 seconds
- **Filter Response:** Filter changes should update charts within 2 seconds
- **Mobile Compatibility:** Test on mobile devices for responsive design

### 3. Data Validation
Verify key metrics match expected values:
- **Total Trips:** 5.7M+ transactions
- **Member Split:** ~64.7% members, ~35.3% casual
- **Data Coverage:** 2023-2024 time period
- **Chart Accuracy:** Spot-check several data points against source files

## Troubleshooting

### Common Deployment Issues

#### Issue 1: Package Installation Errors
**Symptoms:** Deployment fails with package-related errors
**Solution:**
```r
# Install all packages locally first
install.packages(c("shiny", "shinydashboard", "DT", "plotly", "dplyr", "ggplot2", "scales", "viridis"))

# Verify package versions
sessionInfo()
```

#### Issue 2: File Size Limits
**Symptoms:** "Bundle too large" error during upload
**Solution:**
- Check total file size: `du -sh /c/workspace/divvybikes-share-success/deploy`
- Remove unnecessary files from deploy directory
- Compress large CSV files if needed
- Upgrade to paid shinyapps.io plan for higher limits

#### Issue 3: Data Loading Errors
**Symptoms:** Dashboard loads but shows "No data available" messages
**Solution:**
```r
# Test data loading locally
setwd("/c/workspace/divvybikes-share-success/deploy")
data <- read.csv("1_trip_duration_analysis.csv")
head(data)  # Verify data structure
```

#### Issue 4: Authentication Errors
**Symptoms:** "Authentication failed" during deployment
**Solution:**
```r
# Reset authentication
rsconnect::accounts()  # Check current accounts
rsconnect::removeAccount("account-name")  # Remove if needed
# Re-run setAccountInfo() with fresh token
```

### Application-Specific Issues

#### Issue 5: Chart Not Rendering
**Symptoms:** Blank chart areas or error messages in charts
**Debugging Steps:**
1. Check browser console for JavaScript errors
2. Verify data file column names match expectations
3. Test individual chart components locally

#### Issue 6: Filter Functionality
**Symptoms:** Global filters not affecting all charts
**Solution:** 
- Verify reactive data filtering logic in app.R
- Test filter functionality locally before redeploying

## Maintenance and Updates

### Regular Maintenance Tasks

1. **Monthly Data Updates:**
   - Replace CSV files with fresh data
   - Test dashboard locally
   - Redeploy with updated data

2. **Performance Monitoring:**
   - Monitor application metrics in shinyapps.io dashboard
   - Check user engagement statistics
   - Review error logs regularly

3. **Security Updates:**
   - Keep R and packages updated
   - Monitor shinyapps.io security announcements
   - Update authentication tokens as needed

### Update Deployment Process

1. **Test Changes Locally:**
   ```r
   setwd("/c/workspace/divvybikes-share-success/deploy")
   shiny::runApp("app.R")
   ```

2. **Deploy Updates:**
   ```r
   rsconnect::deployApp(
     appDir = "/c/workspace/divvybikes-share-success/deploy",
     appName = "Divvy_analytics_dashboard", 
     forceUpdate = TRUE
   )
   ```

3. **Verify Updates:**
   - Test all functionality on deployed version
   - Check that new features work as expected
   - Monitor for any performance regressions

## Application URLs

### Production Dashboard
- **URL:** https://datafreude.shinyapps.io/Divvy_analytics_dashboard/
- **Status:** Production Ready ✅
- **Last Updated:** August 29, 2025

### Development/Testing URLs
- Create separate applications for testing:
  - `Divvy_analytics_dashboard_dev` for development
  - `Divvy_analytics_dashboard_staging` for staging

## Support and Resources

### Documentation
- **Shiny Documentation:** https://shiny.rstudio.com/
- **shinyapps.io Guide:** https://docs.rstudio.com/shinyapps.io/
- **Plotly R Documentation:** https://plotly.com/r/

### Account Management
- **shinyapps.io Dashboard:** https://www.shinyapps.io/admin/
- **Usage Monitoring:** Monitor active hours and resource usage
- **Log Access:** View application logs for debugging

### Emergency Contacts
- **Platform Issues:** shinyapps.io support
- **Application Issues:** Check GitHub repository issues
- **Data Issues:** Verify source data integrity

## Deployment Checklist

### Pre-Deployment ✅
- [ ] All 13 CSV files present in deploy directory
- [ ] app.R file tested locally and functional
- [ ] Required R packages installed
- [ ] shinyapps.io account configured
- [ ] Authentication token set up

### Deployment ✅
- [ ] Working directory set to deploy folder
- [ ] Deployment command executed successfully
- [ ] No error messages during upload
- [ ] Deployment completion confirmed

### Post-Deployment ✅
- [ ] Dashboard accessible at deployed URL
- [ ] All 5 tabs load without errors
- [ ] KPI value boxes display correct data
- [ ] All charts render and are interactive
- [ ] Global filters function properly
- [ ] Mobile compatibility verified
- [ ] Performance benchmarks met

### Verification ✅
- [ ] Data accuracy spot-checked
- [ ] User acceptance testing completed
- [ ] Documentation updated
- [ ] Stakeholders notified of new deployment

---

## Quick Reference Commands

```r
# Complete deployment workflow
setwd("/c/workspace/divvybikes-share-success/deploy")
library(rsconnect)
deployApp(appName = "Divvy_analytics_dashboard", forceUpdate = TRUE)
```

```bash
# Verify data files
cd /c/workspace/divvybikes-share-success/deploy
ls -la *.csv | wc -l  # Should return 13
```

---

*Last Updated: August 29, 2025*
*Deployment Status: Production Ready ✅*
*Dashboard URL: https://datafreude.shinyapps.io/Divvy_analytics_dashboard/*
