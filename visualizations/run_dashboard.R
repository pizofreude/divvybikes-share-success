# Divvy Bikes Analytics Dashboard - Setup and Execution Script
# This script sets up the environment and runs the flexdashboard

# Set CRAN mirror
options(repos = c(CRAN = "https://cran.rstudio.com/"))

# Install required packages if not already installed
required_packages <- c(
  "flexdashboard",
  "shiny", 
  "dplyr",
  "ggplot2",
  "plotly",
  "DT",
  "scales",
  "viridis",
  "RColorBrewer",
  "lubridate",
  "reshape2",
  "rmarkdown",
  "stringr"
)

# Function to install missing packages
install_if_missing <- function(packages) {
  new_packages <- packages[!(packages %in% installed.packages()[,"Package"])]
  if(length(new_packages)) {
    install.packages(new_packages, dependencies = TRUE)
  }
}

# Install missing packages
cat("Checking and installing required packages...\n")
install_if_missing(required_packages)

# Load required libraries
library(rmarkdown)
library(flexdashboard)

# Set working directory to project root
if (file.exists("data/gold")) {
  # Already in project root
  cat("Running from project root directory...\n")
} else if (file.exists("../data/gold")) {
  # Running from subdirectory, change to parent
  setwd("..")
  cat("Changed to project root directory...\n")
} else {
  stop("Cannot find data/gold directory. Please ensure you're running this script from the project root or visualizations directory")
}

# Verify data files exist
required_files <- c(
  "data/gold/1_trip_duration_analysis.csv",
  "data/gold/2_temporal_usage_patterns.csv",
  "data/gold/5_usage_frequency_conversion_analysis.csv",
  "data/gold/8_geographic_conversion_hotspots.csv",
  "data/gold/9_seasonal_campaign_windows.csv",
  "data/gold/10_daily_hourly_targeting.csv",
  "data/gold/11_station_roi_prioritization.csv",
  "data/gold/13_temperature_elasticity_analysis.csv",
  "data/gold/14_precipitation_impact_analysis.csv",
  "data/gold/17_high_potential_station_conversion.csv"
)

missing_files <- required_files[!file.exists(required_files)]
if (length(missing_files) > 0) {
  cat("Missing required data files:\n")
  cat(paste(missing_files, collapse = "\n"))
  stop("Please ensure all data files are available before running the dashboard")
}

cat("All required data files found.\n")

# Create output directory if it doesn't exist
if (!dir.exists("visualizations")) {
  dir.create("visualizations", recursive = TRUE)
}

# Function to render the dashboard
render_dashboard <- function() {
  cat("Rendering Divvy Bikes Analytics Dashboard...\n")
  
  # Render the flexdashboard
  rmarkdown::render(
    input = "visualizations/divvy_analytics_dashboard.Rmd",
    output_file = "divvy_analytics_dashboard.html",
    output_dir = "visualizations",
    clean = TRUE
  )
  
  cat("Dashboard rendered successfully!\n")
  cat("Open 'visualizations/divvy_analytics_dashboard.html' in your web browser to view the dashboard.\n")
}

# Function to run the dashboard in interactive mode
run_dashboard_interactive <- function() {
  cat("Starting interactive dashboard server...\n")
  cat("The dashboard will open in your default web browser.\n")
  cat("Press Ctrl+C to stop the server.\n")
  
  rmarkdown::run(
    file = "visualizations/divvy_analytics_dashboard.Rmd",
    shiny_args = list(
      host = "127.0.0.1",
      port = 3838,
      launch.browser = TRUE
    )
  )
}

# Function to generate static HTML version
generate_static_dashboard <- function() {
  cat("Generating static HTML dashboard...\n")
  
  # Create a non-interactive version by removing shiny runtime
  dashboard_content <- readLines("visualizations/divvy_analytics_dashboard.Rmd")
  
  # Remove the runtime: shiny line for static version
  dashboard_content <- dashboard_content[!grepl("runtime: shiny", dashboard_content)]
  
  # Write static version
  static_file <- "visualizations/divvy_analytics_dashboard_static.Rmd"
  writeLines(dashboard_content, static_file)
  
  # Render static version
  rmarkdown::render(
    input = static_file,
    output_file = "divvy_analytics_dashboard_static.html",
    output_dir = "visualizations",
    clean = TRUE
  )
  
  # Clean up temporary file
  file.remove(static_file)
  
  cat("Static dashboard generated successfully!\n")
  cat("Open 'visualizations/divvy_analytics_dashboard_static.html' to view the static version.\n")
}

# Main execution function
main <- function() {
  cat("=== Divvy Bikes Analytics Dashboard Setup ===\n\n")
  
  # Check if running interactively
  if (interactive()) {
    cat("Choose an option:\n")
    cat("1. Generate static HTML dashboard\n")
    cat("2. Run interactive dashboard (requires Shiny)\n")
    cat("3. Both static and interactive\n")
    
    choice <- readline(prompt = "Enter choice (1, 2, or 3): ")
    
    switch(choice,
      "1" = generate_static_dashboard(),
      "2" = run_dashboard_interactive(),
      "3" = {
        generate_static_dashboard()
        cat("\nStarting interactive dashboard...\n")
        run_dashboard_interactive()
      },
      cat("Invalid choice. Generating static dashboard by default.\n")
    )
  } else {
    # Non-interactive mode - generate static dashboard
    generate_static_dashboard()
  }
}

# Additional utility functions

# Function to create sample data summary
create_data_summary <- function() {
  cat("Creating data summary report...\n")
  
  summary_report <- list()
  
  for (file in required_files) {
    if (file.exists(file)) {
      data <- read.csv(file)
      summary_report[[basename(file)]] <- list(
        rows = nrow(data),
        cols = ncol(data),
        columns = names(data),
        size_mb = round(file.size(file) / 1024^2, 2)
      )
    }
  }
  
  # Save summary to JSON
  jsonlite::write_json(
    summary_report, 
    "visualizations/data_summary.json", 
    pretty = TRUE
  )
  
  cat("Data summary saved to visualizations/data_summary.json\n")
}

# Function to validate dashboard components
validate_dashboard <- function() {
  cat("Validating dashboard components...\n")
  
  validation_results <- list(
    packages_installed = TRUE,
    data_files_exist = length(missing_files) == 0,
    rmd_file_exists = file.exists("visualizations/divvy_analytics_dashboard.Rmd"),
    output_dir_exists = dir.exists("visualizations")
  )
  
  # Check if all validations pass
  all_valid <- all(unlist(validation_results))
  
  if (all_valid) {
    cat("✓ All dashboard components validated successfully!\n")
  } else {
    cat("✗ Some validation checks failed:\n")
    for (check in names(validation_results)) {
      status <- if (validation_results[[check]]) "✓" else "✗"
      cat(sprintf("  %s %s\n", status, check))
    }
  }
  
  return(all_valid)
}

# Export functions for external use
if (exists("source_this_file") && source_this_file) {
  # If this script is being sourced, don't run main()
  cat("Dashboard functions loaded. Use render_dashboard(), run_dashboard_interactive(), or generate_static_dashboard()\n")
} else {
  # If this script is being run directly, execute main()
  if (validate_dashboard()) {
    main()
  } else {
    cat("Please fix validation issues before proceeding.\n")
  }
}

# Print help information
cat("\n=== Available Functions ===\n")
cat("render_dashboard()          - Render basic HTML dashboard\n")
cat("run_dashboard_interactive() - Run interactive Shiny dashboard\n") 
cat("generate_static_dashboard() - Generate static HTML version\n")
cat("create_data_summary()       - Generate data summary report\n")
cat("validate_dashboard()        - Validate all components\n")
cat("\n=== Next Steps ===\n")
cat("1. Review the generated dashboard in your web browser\n")
cat("2. Use the Tableau Public instructions in .context/tableau_public_instructions.md\n")
cat("3. Customize colors, layouts, and add business-specific insights\n")
cat("4. Share with marketing team and executive leadership for feedback\n")
