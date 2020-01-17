rm(list = ls())
library(tidyverse)

#trips_dir <- "C:/Projects/SANDAG/Otay_Mesa/sr11_ome_v3/data_in/trip_tables/"
trips_dir <- "C:/Projects/SANDAG/Otay_Mesa/sr11_ome_v3/scenario_inputs/2020/Trip_Tables/rds/"
#trips_dir <- "Z:/Otay Mesa/input/Base_year_build/Trip_Tables/rds/"

MAXIMUM_US_ZONE_NUMBER <- 4684

trip_file_vector <- sprintf(paste0(trips_dir, "Trips_%d.RDS"), 1:24)
trips_df_list <- list(length(trip_file_vector))

for(index in 1:length(trip_file_vector)) {
  temp_df <- readRDS(trip_file_vector[index])
  temp_df <- temp_df %>%
    mutate(direction = "Northbound") %>%
    mutate(direction = ifelse(orig <= MAXIMUM_US_ZONE_NUMBER & dest > MAXIMUM_US_ZONE_NUMBER, "Southbound", direction))
  
  trips_df_list[[index]] <- temp_df
  rm(temp_df)
}

if(exists("total_trips_df")) remove("total_trips_df")

# maps of trip table names to vehicle_types and traveler_types
vehicle_type <- c("Passenger", "Passenger", "Passenger", "Commercial", "Commercial")
travel_purpose <- c("HBO", "HBW", "HBS", "Loaded", "Empty")
vehicle_type_travel_purpose_map <- data.frame(vehicle_type, travel_purpose, stringsAsFactors = FALSE)
remove(vehicle_type)

for(hour_index in 1:24) {
  trips_df <- 
    trips_df_list[[hour_index]] %>%
    gather(key = "table", value = "od_trips", -orig, -dest, -direction, na.rm = TRUE) %>%
    separate(table, into = c("travel_purpose", "traveler_type"), sep = "_", remove = TRUE)
  
  trips_df <- left_join(trips_df, vehicle_type_travel_purpose_map, by = c("travel_purpose"))

  trips_df <- 
    trips_df %>%
    group_by(orig, dest, direction, vehicle_type, travel_purpose, traveler_type) %>%
    summarise(od_trips = sum(od_trips))
  
  if (exists("total_trips_df")) {
    total_trips_df <- bind_rows(total_trips_df, trips_df)
  } else {
    total_trips_df <- trips_df
  }
}

total_trips_df %>%
  group_by(vehicle_type, direction) %>%
  summarise(trips = round(sum(od_trips),0)) %>%
  as.data.frame()




