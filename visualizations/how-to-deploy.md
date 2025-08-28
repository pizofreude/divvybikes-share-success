# Divvy Analytics Dashboard - Deployment Guide

## Overview
This guide provides step-by-step instructions for deploying the Divvy Analytics Dashboard to shinyapps.io, including data preparation, configuration, and troubleshooting.

## Prerequisites

### Required Software
- **R** (version 4.0 or higher)
- **RStudio** (recommended for development)
- **Git** (for version control)

### R Packages
Install the following R packages before deployment:
```r
install.packages(c(
  "shiny",
  "shinydashboard", 
  "plotly",
  "DT",
  "dplyr",
  "ggplot2",
  "scales",
  "rsconnect"
))
```

### shinyapps.io Account
1. Create a free account at [shinyapps.io](https://www.shinyapps.io/)
2. Note your account name for configuration
3. Generate authentication tokens (covered in setup section)

## Project Structure

```
deploy/
├── app.R                                    # Main Shiny application
├── *.csv                                   # 13 analytical datasets
└── rsconnect/                              # Deployment configuration
    └── shinyapps.io/
        └── [username]/
            └── [app-name].dcf
```

## Deployment Steps

### Step 1: Prepare Data Files

Ensure all required CSV files are present in the `deploy/` directory:

**Required Datasets:**
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

**Verify Data Integrity:**
```r
# Run this in R to check all files are present
required_files <- c(
  "1_trip_duration_analysis.csv",
  "2_temporal_usage_patterns.csv", 
  "4_bike_type_behavioral_analysis_main.csv",
  "5_usage_frequency_conversion_analysis.csv",
  "6_behavioral_similarity_analysis.csv",
  "7_temporal_conversion_patterns.csv",
  "8_geographic_conversion_hotspots.csv",
  "9_seasonal_campaign_windows.csv",
  "10_daily_hourly_targeting.csv",
  "11_station_roi_prioritization.csv",
  "13_temperature_elasticity_analysis.csv",
  "14_precipitation_impact_analysis.csv",
  "17_high_potential_station_conversion.csv"
)

setwd("deploy/")
missing_files <- required_files[!file.exists(required_files)]
if(length(missing_files) == 0) {
  cat("✅ All data files present!\n")
} else {
  cat("❌ Missing files:\n")
  cat(paste(missing_files, collapse = "\n"))
}
```

### Step 2: Configure shinyapps.io Authentication

**In RStudio/R Console:**
```r
# Install rsconnect if not already installed
if (!require("rsconnect")) install.packages("rsconnect")
library(rsconnect)

# Set up your shinyapps.io account
# Replace with your actual account details from shinyapps.io dashboard
rsconnect::setAccountInfo(
  name='YOUR_USERNAME',
  token='YOUR_TOKEN',
  secret='YOUR_SECRET'
)
```

**To get your token and secret:**
1. Log in to [shinyapps.io](https://www.shinyapps.io/)
2. Go to Account → Tokens
3. Click "Show" next to your token
4. Copy the `rsconnect::setAccountInfo()` command provided

### Step 3: Test Locally

Before deploying, test the dashboard locally:

```r
# Set working directory to deploy folder
setwd("path/to/your/project/deploy/")

# Run the app locally
shiny::runApp("app.R")
```

**Local Testing Checklist:**
- [ ] Dashboard loads without errors
- [ ] All 5 tabs are accessible
- [ ] Charts render correctly in each tab
- [ ] Filters work properly (Year and User Type)
- [ ] Data tables display correctly
- [ ] No console errors in browser developer tools

### Step 4: Deploy to shinyapps.io

**Option A: Using RStudio (Recommended)**
1. Open `app.R` in RStudio
2. Click the "Publish" button (blue icon) in the top-right of the source pane
3. Select "Publish Application"
4. Choose "shinyapps.io" as the destination
5. Select all CSV files to include
6. Choose an application name (e.g., "Divvy_analytics_dashboard")
7. Click "Publish"

**Option B: Using R Console**
```r
# Set working directory to deploy folder
setwd("deploy/")

# Deploy the application
rsconnect::deployApp(
  appDir = ".",
  appName = "Divvy_analytics_dashboard",
  account = "YOUR_USERNAME",
  launch.browser = TRUE
)
```

### Step 5: Verify Deployment

After deployment:
1. **Check URL**: Your app will be available at `https://YOUR_USERNAME.shinyapps.io/Divvy_analytics_dashboard/`
2. **Test Functionality**: Verify all features work as expected
3. **Monitor Logs**: Check the logs in shinyapps.io dashboard for any errors

## Configuration Options

### Application Settings

**In shinyapps.io Dashboard:**
- **Instance Size**: Use default (1 GB RAM) for normal usage
- **Instance Idle Timeout**: Recommend 15 minutes
- **Max Connections**: Default (25) should be sufficient
- **Max Session Duration**: Default (8 hours)

### Data Update Process

To update data without redeploying the entire app:
```r
# Update specific CSV files and redeploy
rsconnect::deployApp(
  appDir = "deploy/",
  appName = "Divvy_analytics_dashboard", 
  forceUpdate = TRUE
)
```

## Troubleshooting

### Common Issues

**1. "Object not found" errors**
- **Cause**: Missing or incorrectly named CSV files
- **Solution**: Verify all required CSV files are in the deploy directory with exact names

**2. "Package not available" errors**
- **Cause**: Missing R packages in deployment environment
- **Solution**: Ensure all packages are listed at the top of `app.R`:
```r
library(shiny)
library(shinydashboard)
library(plotly)
library(DT)
library(dplyr)
library(ggplot2)
library(scales)
```

**3. Charts not rendering**
- **Cause**: Data format issues or missing columns
- **Solution**: Check data structure matches expected format:
```r
# Example validation for duration data
duration_data <- read.csv("1_trip_duration_analysis.csv")
required_cols <- c("duration_category", "percentage_of_user_trips", "member_casual")
missing_cols <- required_cols[!required_cols %in% names(duration_data)]
if(length(missing_cols) > 0) {
  cat("Missing columns:", paste(missing_cols, collapse = ", "))
}
```

**4. Deployment timeout**
- **Cause**: Large files or slow upload
- **Solution**: Check file sizes and internet connection:
```r
# Check file sizes
file_sizes <- sapply(list.files(pattern = "*.csv"), file.size)
large_files <- file_sizes[file_sizes > 1e6]  # Files > 1MB
if(length(large_files) > 0) {
  cat("Large files detected:\n")
  print(large_files)
}
```

**5. Memory errors**
- **Cause**: Large datasets or inefficient data loading
- **Solution**: Optimize data loading in `app.R` or upgrade to larger instance

### Log Analysis

**Access logs in shinyapps.io:**
1. Go to your dashboard
2. Click on your application
3. Go to "Logs" tab
4. Check for error messages

**Common log patterns:**
- `Error in read.csv()`: File reading issues
- `Object 'X' not found`: Missing data or variable issues
- `could not find function`: Missing package imports

## Performance Optimization

### Data Optimization
- **File Size**: Keep CSV files under 10MB each
- **Data Types**: Use appropriate data types in R
- **Filtering**: Pre-filter data when possible

### Code Optimization
```r
# Example: Efficient data loading
load_data_efficiently <- function() {
  # Read all files once at startup
  data_files <- list.files(pattern = "*.csv", full.names = TRUE)
  dashboard_data <- lapply(data_files, function(f) {
    data <- read.csv(f, stringsAsFactors = FALSE)
    return(data)
  })
  names(dashboard_data) <- gsub(".csv", "", basename(data_files))
  return(dashboard_data)
}
```

### Instance Management
- **Monitor Usage**: Check active hours in shinyapps.io dashboard
- **Upgrade When Needed**: Consider paid plans for high traffic
- **Multiple Instances**: Use staging and production environments

## Maintenance

### Regular Updates
1. **Data Refresh**: Monthly data updates from dbt pipeline
2. **Code Updates**: Version control with Git
3. **Dependency Updates**: Keep R packages current

### Backup Strategy
```bash
# Backup deployment configuration
cp -r deploy/rsconnect/ backup/rsconnect-$(date +%Y%m%d)/

# Backup current CSV files
tar -czf backup/data-$(date +%Y%m%d).tar.gz deploy/*.csv
```

### Version Control
```bash
# Tag releases for version tracking
git tag -a v1.0 -m "Production deployment v1.0"
git push origin v1.0
```

## Security Considerations

### Data Protection
- **No Sensitive Data**: Ensure CSV files contain only aggregated, non-PII data
- **Access Control**: Use shinyapps.io authentication if needed
- **HTTPS**: Always use HTTPS URLs (automatic with shinyapps.io)

### Code Security
- **No Hardcoded Secrets**: Keep all sensitive info out of code
- **Input Validation**: Validate user inputs in Shiny app
- **Error Handling**: Implement graceful error handling

## Support and Resources

### Documentation
- [Shiny Documentation](https://shiny.rstudio.com/)
- [shinyapps.io User Guide](https://docs.rstudio.com/shinyapps.io/)
- [Plotly R Documentation](https://plotly.com/r/)

### Community Support
- [RStudio Community](https://community.rstudio.com/)
- [Stack Overflow - Shiny](https://stackoverflow.com/questions/tagged/shiny)
- [GitHub Issues](https://github.com/pizofreude/divvybikes-share-success/issues)

---

**Dashboard URL:** [datafreude.shinyapps.io/Divvy_analytics_dashboard](https://datafreude.shinyapps.io/Divvy_analytics_dashboard/)

**Last Updated:** August 29, 2025
**Status:** Production Ready ✅
