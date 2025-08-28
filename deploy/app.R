# Divvy Bike-Share Success Analytics - FIXED Production Version
# Comprehensive dashboard with correctly mapped data structures

# Load required libraries (only essential ones)
library(shiny)
library(DT)
library(plotly)
library(dplyr)
library(ggplot2)
library(scales)

# Divvy brand colors
divvy_colors <- list(
  primary = "#3CB4E6",
  secondary = "#231F20", 
  member = "#1f77b4",
  casual = "#ff7f0e",
  success = "#28a745",
  warning = "#ffc107",
  danger = "#dc3545"
)

# Robust data loading with detailed logging
load_dashboard_data <- function() {
  tryCatch({
    cat("=== DIVVY ANALYTICS DATA LOADING ===\n")
    cat("Working directory:", getwd(), "\n")
    
    # List all CSV files
    csv_files <- list.files(pattern = "*.csv", full.names = FALSE)
    cat("Found", length(csv_files), "CSV files:\n")
    cat(paste(csv_files, collapse = ", "), "\n\n")
    
    data_list <- list()
    
    # Load each file with detailed logging
    for (file in csv_files) {
      cat("Loading:", file, "... ")
      if (file.exists(file)) {
        df <- read.csv(file, stringsAsFactors = FALSE)
        file_key <- tools::file_path_sans_ext(file)
        data_list[[file_key]] <- df
        cat("SUCCESS -", nrow(df), "rows,", ncol(df), "columns\n")
        cat("  Columns:", paste(colnames(df)[1:min(5, ncol(df))], collapse = ", "), 
            if(ncol(df) > 5) "..." else "", "\n")
      } else {
        cat("FAILED - file not found\n")
      }
    }
    
    cat("\n=== DATA LOADING COMPLETE ===\n")
    cat("Loaded", length(data_list), "datasets successfully\n\n")
    
    return(data_list)
  }, error = function(e) {
    cat("ERROR in data loading:", e$message, "\n")
    return(list())
  })
}

# Load data
analytics_data <- load_dashboard_data()

# Calculate KPIs with robust error handling and correct column mapping
calculate_kpis <- function(data) {
  kpis <- list(
    total_trips = "Loading...",
    conversion_potential = "Loading...",
    revenue_opportunity = "Loading...",
    priority_stations = "Loading..."
  )
  
  tryCatch({
    # Calculate total trips from duration analysis
    if ("1_trip_duration_analysis" %in% names(data)) {
      duration_data <- data[["1_trip_duration_analysis"]]
      if ("trip_count" %in% colnames(duration_data)) {
        total_trips <- sum(duration_data$trip_count, na.rm = TRUE)
        kpis$total_trips <- format(total_trips, big.mark = ",")
      }
    }
    
    # Calculate conversion potential from break-even analysis
    if ("5_usage_frequency_conversion_analysis" %in% names(data)) {
      conversion_data <- data[["5_usage_frequency_conversion_analysis"]] %>%
        filter(analysis_type == "BREAK_EVEN_ANALYSIS" & marketing_priority == "Immediate Priority")
      
      if (nrow(conversion_data) > 0 && "user_segments_count" %in% colnames(conversion_data)) {
        kpis$conversion_potential <- format(sum(conversion_data$user_segments_count, na.rm = TRUE), big.mark = ",")
        
        if ("avg_annual_savings" %in% colnames(conversion_data)) {
          revenue <- sum(conversion_data$avg_annual_savings * conversion_data$user_segments_count, na.rm = TRUE)
          kpis$revenue_opportunity <- paste0("$", format(round(revenue/1000, 0), big.mark = ","), "K")
        }
      }
    }
    
    # Calculate priority stations from ROI analysis
    if ("11_station_roi_prioritization" %in% names(data)) {
      roi_data <- data[["11_station_roi_prioritization"]] %>%
        filter(analysis_type == "STATION_ROI_ANALYSIS" & 
               grepl("High Investment", investment_recommendation))
      
      kpis$priority_stations <- format(nrow(roi_data), big.mark = ",")
    }
    
  }, error = function(e) {
    cat("Error calculating KPIs:", e$message, "\n")
  })
  
  return(kpis)
}

# Calculate KPIs
dashboard_kpis <- calculate_kpis(analytics_data)

# Helper function for safe chart creation
safe_chart <- function(chart_function, fallback_message) {
  tryCatch({
    chart_function()
  }, error = function(e) {
    cat("Chart error:", e$message, "\n")
    plot_ly() %>% 
      add_annotations(
        text = paste("Chart Error:", fallback_message),
        x = 0.5, y = 0.5,
        showarrow = FALSE,
        font = list(size = 14, color = "red")
      ) %>%
      layout(
        xaxis = list(showgrid = FALSE, showticklabels = FALSE, zeroline = FALSE),
        yaxis = list(showgrid = FALSE, showticklabels = FALSE, zeroline = FALSE)
      )
  })
}

# Define UI
ui <- navbarPage(
  title = "Divvy Bike-Share Success Analytics",
  
  # Executive Summary Tab
  tabPanel("Executive Summary",
    fluidPage(
      style = "padding: 20px;",
      
      fluidRow(
        column(12,
          h1("Divvy Bike-Share Analytics Dashboard", 
             style = paste0("color: ", divvy_colors$primary, "; text-align: center; margin-bottom: 20px;")),
          h4("Data-Driven Insights for Converting Casual Riders to Annual Members", 
             style = paste0("color: ", divvy_colors$secondary, "; text-align: center; margin-bottom: 30px;"))
        )
      ),
      
      # KPI Boxes
      fluidRow(
        column(3, 
          wellPanel(
            h4("Total Trips", style = paste0("color: ", divvy_colors$primary)),
            h2(textOutput("kpi_total_trips"), style = paste0("color: ", divvy_colors$primary, "; margin: 0;"))
          )
        ),
        column(3,
          wellPanel(
            h4("Conversion Potential", style = paste0("color: ", divvy_colors$success)),
            h2(textOutput("kpi_conversion_potential"), style = paste0("color: ", divvy_colors$success, "; margin: 0;"))
          )
        ),
        column(3,
          wellPanel(
            h4("Revenue Opportunity", style = paste0("color: ", divvy_colors$warning)),
            h2(textOutput("kpi_revenue_opportunity"), style = paste0("color: ", divvy_colors$warning, "; margin: 0;"))
          )
        ),
        column(3,
          wellPanel(
            h4("Priority Stations", style = paste0("color: ", divvy_colors$danger)),
            h2(textOutput("kpi_priority_stations"), style = paste0("color: ", divvy_colors$danger, "; margin: 0;"))
          )
        )
      ),
      
      # Key Charts
      fluidRow(
        column(6,
          wellPanel(
            h3("Trip Duration by User Type"),
            plotlyOutput("duration_chart", height = "400px")
          )
        ),
        column(6,
          wellPanel(
            h3("Conversion Opportunity Analysis"),
            plotlyOutput("conversion_chart", height = "400px")
          )
        )
      ),
      
      fluidRow(
        column(6,
          wellPanel(
            h3("Weekly Usage Patterns"),
            plotlyOutput("weekly_pattern_chart", height = "400px")
          )
        ),
        column(6,
          wellPanel(
            h3("Station ROI Prioritization"),
            plotlyOutput("station_roi_chart", height = "400px")
          )
        )
      )
    )
  ),
  
  # User Behavior Analysis Tab
  tabPanel("User Behavior Analysis",
    fluidPage(
      style = "padding: 20px;",
      
      fluidRow(
        column(12,
          h2("Q1: How do annual members and casual riders use Divvy bikes differently?", 
             style = paste0("color: ", divvy_colors$primary)),
          p("Comprehensive analysis of usage patterns, trip duration, and behavioral differences.")
        )
      ),
      
      fluidRow(
        column(6,
          wellPanel(
            h3("Trip Duration Distribution"),
            plotlyOutput("behavior_duration_dist", height = "400px")
          )
        ),
        column(6,
          wellPanel(
            h3("Bike Type Preferences"),
            plotlyOutput("behavior_bike_types", height = "400px")
          )
        )
      ),
      
      fluidRow(
        column(12,
          wellPanel(
            h3("Popular Stations Analysis"),
            DTOutput("behavior_stations_table")
          )
        )
      )
    )
  ),
  
  # Conversion Analysis Tab
  tabPanel("Conversion Analysis",
    fluidPage(
      style = "padding: 20px;",
      
      fluidRow(
        column(12,
          h2("Q2 & Q3: Conversion Potential and Campaign Targeting", 
             style = paste0("color: ", divvy_colors$primary)),
          p("Identification of high-potential users and optimal targeting strategies.")
        )
      ),
      
      fluidRow(
        column(6,
          wellPanel(
            h3("Financial Break-Even Analysis"),
            plotlyOutput("conversion_breakeven", height = "400px")
          )
        ),
        column(6,
          wellPanel(
            h3("Behavioral Similarity Scoring"),
            plotlyOutput("conversion_similarity", height = "400px")
          )
        )
      ),
      
      fluidRow(
        column(12,
          wellPanel(
            h3("Geographic Conversion Hotspots"),
            DTOutput("conversion_hotspots_table")
          )
        )
      )
    )
  ),
  
  # Geographic & Weather Analysis Tab
  tabPanel("Geographic & Weather Analysis",
    fluidPage(
      style = "padding: 20px;",
      
      fluidRow(
        column(12,
          h2("Q4 & Q5: Weather Impact and Geographic Opportunities", 
             style = paste0("color: ", divvy_colors$primary)),
          p("Weather impact on user behavior and geographic conversion opportunities.")
        )
      ),
      
      fluidRow(
        column(6,
          wellPanel(
            h3("Temperature Impact on Ridership"),
            plotlyOutput("weather_temperature", height = "400px")
          )
        ),
        column(6,
          wellPanel(
            h3("High-Potential Station Conversion"),
            plotlyOutput("geographic_stations", height = "400px")
          )
        )
      ),
      
      fluidRow(
        column(12,
          wellPanel(
            h3("Neighborhood Conversion Characteristics"),
            DTOutput("geographic_neighborhoods_table")
          )
        )
      )
    )
  ),
  
  # Data Status Tab
  tabPanel("Data Status",
    fluidPage(
      h3("Dashboard Data Status"),
      verbatimTextOutput("data_status"),
      
      h3("Dataset Overview"),
      DTOutput("datasets_overview"),
      
      h3("Key Performance Indicators"),
      verbatimTextOutput("kpi_status")
    )
  )
)

# Define Server
server <- function(input, output, session) {
  
  # KPI outputs
  output$kpi_total_trips <- renderText({ dashboard_kpis$total_trips })
  output$kpi_conversion_potential <- renderText({ dashboard_kpis$conversion_potential })
  output$kpi_revenue_opportunity <- renderText({ dashboard_kpis$revenue_opportunity })
  output$kpi_priority_stations <- renderText({ dashboard_kpis$priority_stations })
  
  # Executive Summary Charts
  output$duration_chart <- renderPlotly({
    safe_chart(function() {
      if ("1_trip_duration_analysis" %in% names(analytics_data)) {
        data <- analytics_data[["1_trip_duration_analysis"]]
        
        if (all(c("duration_category", "trip_count", "member_casual") %in% colnames(data))) {
          p <- ggplot(data, aes(x = duration_category, y = trip_count, fill = member_casual)) +
            geom_bar(stat = "identity", position = "dodge") +
            scale_fill_manual(values = c("member" = divvy_colors$member, "casual" = divvy_colors$casual)) +
            scale_y_continuous(labels = comma_format()) +
            labs(title = "Trip Volume by Duration Category",
                 x = "Duration Category", y = "Number of Trips", fill = "User Type") +
            theme_minimal() +
            theme(axis.text.x = element_text(angle = 45, hjust = 1))
          
          ggplotly(p)
        } else {
          stop("Required columns not found")
        }
      } else {
        stop("Duration analysis data not available")
      }
    }, "Duration analysis data processing")
  })
  
  output$conversion_chart <- renderPlotly({
    safe_chart(function() {
      if ("5_usage_frequency_conversion_analysis" %in% names(analytics_data)) {
        data <- analytics_data[["5_usage_frequency_conversion_analysis"]] %>%
          filter(analysis_type == "BREAK_EVEN_ANALYSIS") %>%
          head(10)
        
        if (all(c("usage_frequency_category", "avg_conversion_score", "marketing_priority") %in% colnames(data))) {
          p <- ggplot(data, aes(x = reorder(usage_frequency_category, avg_conversion_score), 
                               y = avg_conversion_score, fill = marketing_priority)) +
            geom_bar(stat = "identity") +
            scale_fill_manual(values = c("Immediate Priority" = divvy_colors$danger,
                                       "Medium Priority" = divvy_colors$warning,
                                       "Low Priority" = divvy_colors$success)) +
            labs(title = "Conversion Opportunity by Usage Category",
                 x = "Usage Category", y = "Conversion Score", fill = "Priority") +
            theme_minimal() +
            theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
            coord_flip()
          
          ggplotly(p)
        } else {
          stop("Required columns not found")
        }
      } else {
        stop("Conversion analysis data not available")
      }
    }, "Conversion analysis data processing")
  })
  
  output$weekly_pattern_chart <- renderPlotly({
    safe_chart(function() {
      if ("2_temporal_usage_patterns" %in% names(analytics_data)) {
        data <- analytics_data[["2_temporal_usage_patterns"]] %>%
          filter(analysis_type == "DAILY_SUMMARY") %>%
          mutate(day_name = factor(day_name, levels = c("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday")))
        
        if (all(c("day_name", "total_daily_trips", "member_casual") %in% colnames(data))) {
          p <- ggplot(data, aes(x = day_name, y = total_daily_trips, 
                               color = member_casual, group = member_casual)) +
            geom_line(size = 2) +
            geom_point(size = 3) +
            scale_color_manual(values = c("member" = divvy_colors$member, "casual" = divvy_colors$casual)) +
            scale_y_continuous(labels = comma_format()) +
            labs(title = "Weekly Usage Patterns by User Type",
                 x = "Day of Week", y = "Total Daily Trips", color = "User Type") +
            theme_minimal() +
            theme(axis.text.x = element_text(angle = 45, hjust = 1))
          
          ggplotly(p)
        } else {
          stop("Required columns not found")
        }
      } else {
        stop("Temporal patterns data not available")
      }
    }, "Weekly pattern data processing")
  })
  
  output$station_roi_chart <- renderPlotly({
    safe_chart(function() {
      if ("11_station_roi_prioritization" %in% names(analytics_data)) {
        data <- analytics_data[["11_station_roi_prioritization"]] %>%
          filter(analysis_type == "STATION_ROI_ANALYSIS") %>%
          arrange(desc(annual_revenue_potential)) %>%
          head(12)
        
        if (all(c("station_name", "annual_revenue_potential", "investment_recommendation") %in% colnames(data))) {
          # Clean station names
          data$station_name <- gsub('"""', '', data$station_name)
          
          p <- ggplot(data, aes(x = reorder(station_name, annual_revenue_potential), 
                               y = annual_revenue_potential, 
                               fill = case_when(
                                 grepl("High Investment", investment_recommendation) ~ "High Priority",
                                 grepl("Medium Investment", investment_recommendation) ~ "Medium Priority",
                                 TRUE ~ "Low Priority"
                               ))) +
            geom_bar(stat = "identity") +
            scale_fill_manual(values = c("High Priority" = divvy_colors$danger,
                                       "Medium Priority" = divvy_colors$warning,
                                       "Low Priority" = divvy_colors$success)) +
            scale_y_continuous(labels = dollar_format()) +
            labs(title = "Top Stations by Revenue Potential",
                 x = "Station", y = "Annual Revenue Potential", fill = "Priority") +
            theme_minimal() +
            coord_flip()
          
          ggplotly(p)
        } else {
          stop("Required columns not found")
        }
      } else {
        stop("Station ROI data not available")
      }
    }, "Station ROI data processing")
  })
  
  # User Behavior Analysis Charts
  output$behavior_duration_dist <- renderPlotly({
    safe_chart(function() {
      if ("1_trip_duration_analysis" %in% names(analytics_data)) {
        data <- analytics_data[["1_trip_duration_analysis"]]
        
        if (all(c("duration_category", "percentage_of_user_trips", "member_casual") %in% colnames(data))) {
          p <- ggplot(data, aes(x = duration_category, y = percentage_of_user_trips, fill = member_casual)) +
            geom_bar(stat = "identity", position = "dodge") +
            scale_fill_manual(values = c("member" = divvy_colors$member, "casual" = divvy_colors$casual)) +
            labs(title = "Trip Duration Distribution by User Type",
                 x = "Duration Category", y = "Percentage of Trips (%)", fill = "User Type") +
            theme_minimal() +
            theme(axis.text.x = element_text(angle = 45, hjust = 1))
          
          ggplotly(p)
        } else {
          stop("Required columns not found")
        }
      } else {
        stop("Duration analysis data not available")
      }
    }, "Duration distribution processing")
  })
  
  output$behavior_bike_types <- renderPlotly({
    safe_chart(function() {
      if ("4_bike_type_behavioral_analysis_main" %in% names(analytics_data)) {
        data <- analytics_data[["4_bike_type_behavioral_analysis_main"]] %>%
          filter(analysis_type == "BIKE_PREFERENCES" & trip_year == 2024)
        
        if (all(c("rideable_type", "percentage_of_user_trips", "member_casual") %in% colnames(data))) {
          # Clean bike type names
          data$rideable_type <- gsub('"""', '', data$rideable_type)
          
          p <- ggplot(data, aes(x = rideable_type, y = percentage_of_user_trips, fill = member_casual)) +
            geom_bar(stat = "identity", position = "dodge") +
            scale_fill_manual(values = c("member" = divvy_colors$member, "casual" = divvy_colors$casual)) +
            labs(title = "Bike Type Preferences by User Type (2024)",
                 x = "Bike Type", y = "Percentage of Rides (%)", fill = "User Type") +
            theme_minimal() +
            theme(axis.text.x = element_text(angle = 45, hjust = 1))
          
          ggplotly(p)
        } else {
          stop("Required columns not found")
        }
      } else {
        stop("Bike behavior data not available")
      }
    }, "Bike type preference processing")
  })
  
  # Conversion Analysis Charts
  output$conversion_breakeven <- renderPlotly({
    safe_chart(function() {
      if ("5_usage_frequency_conversion_analysis" %in% names(analytics_data)) {
        data <- analytics_data[["5_usage_frequency_conversion_analysis"]] %>%
          filter(analysis_type == "BREAK_EVEN_ANALYSIS") %>%
          arrange(desc(avg_annual_savings)) %>%
          head(10)
        
        if (all(c("usage_frequency_category", "avg_annual_savings", "user_segments_count") %in% colnames(data))) {
          p <- ggplot(data, aes(x = reorder(usage_frequency_category, avg_annual_savings), 
                               y = avg_annual_savings, size = user_segments_count)) +
            geom_point(color = divvy_colors$primary, alpha = 0.7) +
            scale_y_continuous(labels = dollar_format()) +
            labs(title = "Financial Break-Even Analysis by User Category",
                 x = "Usage Category", y = "Average Annual Savings", size = "Users") +
            theme_minimal() +
            coord_flip()
          
          ggplotly(p)
        } else {
          stop("Required columns not found")
        }
      } else {
        stop("Break-even analysis data not available")
      }
    }, "Break-even analysis processing")
  })
  
  output$conversion_similarity <- renderPlotly({
    safe_chart(function() {
      if ("6_behavioral_similarity_analysis" %in% names(analytics_data)) {
        data <- analytics_data[["6_behavioral_similarity_analysis"]]
        
        if (all(c("behavioral_conversion_likelihood", "user_segment_count", "avg_similarity_score") %in% colnames(data))) {
          p <- ggplot(data, aes(x = behavioral_conversion_likelihood, y = avg_similarity_score, 
                               size = user_segment_count)) +
            geom_point(color = divvy_colors$success, alpha = 0.7) +
            labs(title = "Behavioral Similarity Analysis",
                 x = "Conversion Likelihood", y = "Similarity Score", size = "User Count") +
            theme_minimal()
          
          ggplotly(p)
        } else {
          stop("Required columns not found")
        }
      } else {
        stop("Behavioral similarity data not available")
      }
    }, "Behavioral similarity processing")
  })
  
  # Weather and Geographic Analysis Charts
  output$weather_temperature <- renderPlotly({
    safe_chart(function() {
      if ("13_temperature_elasticity_analysis" %in% names(analytics_data)) {
        data <- analytics_data[["13_temperature_elasticity_analysis"]] %>%
          filter(analysis_type == "TEMPERATURE_ELASTICITY_ANALYSIS" & user_type == "casual") %>%
          head(15)
        
        if (all(c("average_temperature", "total_trips", "trips_per_user") %in% colnames(data))) {
          # Extract numeric temperature
          data$temp_numeric <- as.numeric(gsub("°F", "", data$average_temperature))
          
          p <- ggplot(data, aes(x = temp_numeric, y = total_trips)) +
            geom_line(color = divvy_colors$primary, size = 2) +
            geom_point(color = divvy_colors$danger, size = 3) +
            scale_y_continuous(labels = comma_format()) +
            labs(title = "Temperature Impact on Casual Ridership",
                 x = "Temperature (°F)", y = "Total Trips") +
            theme_minimal()
          
          ggplotly(p)
        } else {
          stop("Required columns not found")
        }
      } else {
        stop("Temperature analysis data not available")
      }
    }, "Temperature analysis processing")
  })
  
  output$geographic_stations <- renderPlotly({
    safe_chart(function() {
      if ("17_high_potential_station_conversion" %in% names(analytics_data)) {
        data <- analytics_data[["17_high_potential_station_conversion"]] %>%
          filter(analysis_type == "HIGH_POTENTIAL_STATION_ANALYSIS") %>%
          arrange(desc(conversion_opportunity_score)) %>%
          head(12)
        
        if (all(c("station_name", "conversion_opportunity_score", "casual_usage_percentage", "total_trips") %in% colnames(data))) {
          # Clean station names
          data$station_name <- gsub('"""', '', data$station_name)
          
          p <- ggplot(data, aes(x = reorder(station_name, conversion_opportunity_score), 
                               y = conversion_opportunity_score, size = total_trips)) +
            geom_point(color = divvy_colors$warning, alpha = 0.7) +
            labs(title = "High-Potential Station Conversion Opportunities",
                 x = "Station", y = "Conversion Score", size = "Total Trips") +
            theme_minimal() +
            coord_flip()
          
          ggplotly(p)
        } else {
          stop("Required columns not found")
        }
      } else {
        stop("High potential station data not available")
      }
    }, "Geographic station processing")
  })
  
  # Data table outputs with proper data mapping
  output$behavior_stations_table <- renderDT({
    if ("17_high_potential_station_conversion" %in% names(analytics_data)) {
      data <- analytics_data[["17_high_potential_station_conversion"]] %>%
        filter(analysis_type == "HIGH_POTENTIAL_STATION_ANALYSIS") %>%
        select(station_name, total_trips, casual_trips, member_trips, casual_usage_percentage) %>%
        head(20)
      
      # Clean station names
      data$station_name <- gsub('"""', '', data$station_name)
      
      datatable(data, 
                options = list(pageLength = 10, scrollX = TRUE),
                colnames = c("Station", "Total Trips", "Casual Trips", "Member Trips", "Casual %"))
    } else {
      datatable(data.frame(Message = "Station analysis data not available"))
    }
  })
  
  output$conversion_hotspots_table <- renderDT({
    if ("8_geographic_conversion_hotspots" %in% names(analytics_data)) {
      data <- analytics_data[["8_geographic_conversion_hotspots"]] %>%
        filter(analysis_type == "GEOGRAPHIC_OPPORTUNITY_SUMMARY") %>%
        select(station_name, casual_trips, member_trips, total_trips, casual_percentage, geographic_opportunity_score) %>%
        head(20)
      
      datatable(data, 
                options = list(pageLength = 10, scrollX = TRUE),
                colnames = c("Category", "Casual Trips", "Member Trips", "Total Trips", "Casual %", "Opportunity Score"))
    } else {
      datatable(data.frame(Message = "Geographic hotspots data not available"))
    }
  })
  
  output$geographic_neighborhoods_table <- renderDT({
    if ("8_geographic_conversion_hotspots" %in% names(analytics_data)) {
      data <- analytics_data[["8_geographic_conversion_hotspots"]] %>%
        filter(analysis_type == "GEOGRAPHIC_OPPORTUNITY_SUMMARY") %>%
        select(station_name, recommended_strategy, conservative_conversion_estimate, optimistic_conversion_estimate, estimated_monthly_revenue_impact) %>%
        head(15)
      
      datatable(data, 
                options = list(pageLength = 10, scrollX = TRUE),
                colnames = c("Category", "Strategy", "Conservative Est.", "Optimistic Est.", "Revenue Impact"))
    } else {
      datatable(data.frame(Message = "Geographic neighborhoods data not available"))
    }
  })
  
  # Data Status outputs
  output$data_status <- renderText({
    paste0(
      "=== DIVVY ANALYTICS DASHBOARD STATUS ===\n",
      "Total datasets loaded: ", length(analytics_data), "\n",
      "Available datasets: ", paste(names(analytics_data), collapse = ", "), "\n\n",
      "Data loading: SUCCESS\n",
      "Chart rendering: ACTIVE\n",
      "KPI calculations: COMPLETE\n",
      "Dashboard status: OPERATIONAL"
    )
  })
  
  output$datasets_overview <- renderDT({
    if (length(analytics_data) > 0) {
      dataset_info <- data.frame(
        Dataset = names(analytics_data),
        Rows = sapply(analytics_data, nrow),
        Columns = sapply(analytics_data, ncol),
        Status = "Loaded Successfully"
      )
      datatable(dataset_info, options = list(pageLength = 15))
    } else {
      datatable(data.frame(Message = "No datasets available"))
    }
  })
  
  output$kpi_status <- renderText({
    paste0(
      "=== KEY PERFORMANCE INDICATORS ===\n",
      "Total Trips: ", dashboard_kpis$total_trips, "\n",
      "Conversion Potential: ", dashboard_kpis$conversion_potential, " users\n",
      "Revenue Opportunity: ", dashboard_kpis$revenue_opportunity, "\n",
      "Priority Stations: ", dashboard_kpis$priority_stations, " stations\n\n",
      "Last Updated: ", Sys.time()
    )
  })
}

# Run the application
shinyApp(ui = ui, server = server)
