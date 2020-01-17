# Port of Entry Choice Model Parameters and Methods

# -----------------------------------------------------------------------------------
# Parameters
# in-vehicle time in utils per minute
K_TRAVEL_TIME <- -0.025
K_PORT_TIME <- 2.5 * K_TRAVEL_TIME

# utility if alternative is unavailable
MISSING_UTILITY <- -9999.0

# -----------------------------------------------------------------------------------
# TransCAD Trip Matrix as CSV to RDS Conversion
TransCAD_Trip_CSV_Matrix_to_R <- function(input_csv_matrix_file, input_dcc_matrix_file, output_r_dataframe_file, input_desired_cols){
  # TESTING
  # input_csv_matrix_file <- tc_csv_mtx_file
  # input_dcc_matrix_file <- tc_dcc_mtx_file
  # output_r_dataframe_file <- r_df_file
  # input_desired_cols <- desired_non_zero_trip_table_vector
  
  data_df <- fread(input_csv_matrix_file, sep = ",", header = FALSE)
  dcc_df <- read.csv(input_dcc_matrix_file, header = FALSE, skip = 2)
  
  # remove any spaces in the variable names
  variable_names <- paste(dcc_df$V1)
  variable_names <- gsub(" ", "_", variable_names)
  
  variable_names[1] <- "orig"
  variable_names[2] <- "dest"
  
  colnames(data_df) <- variable_names
  
  if (!missing(input_desired_cols)) {
    
    if (exists("run_df")) remove(run_df)
    if (exists("work_df")) remove(work_df)
    for (desired_col in input_desired_cols) {
      
      desired_cols <- c("orig", "dest", desired_col)
      
      work_df <- select(data_df, matches = desired_cols)
      
      work_df <- 
        work_df %>%
        filter(!is.na(matches3))
      
      colnames(work_df) <- desired_cols
      
      if (exists("run_df")) {
        run_df <- full_join(run_df, work_df, by = c("orig", "dest"))
      } else {
        run_df <- work_df
      }
      
    } # for cols
    
  }
  
  saveRDS(run_df, file = output_r_dataframe_file)
  
}

# -----------------------------------------------------------------------------------
# Helper Function TODO: comment up properly
TransCAD_Skim_CSV_Matrix_to_R <- function(input_csv_matrix_file, input_dcc_matrix_file, output_r_dataframe_file, input_port_zone_vector){
  
  data_df <- fread(input_csv_matrix_file, sep = ",", header = FALSE)
  dcc_df <- read.csv(input_dcc_matrix_file, header = FALSE, skip = 2)
  
  # remove any spaces in the variable names
  variable_names <- paste(dcc_df$V1)
  variable_names <- gsub(" ", "_", variable_names)
  
  variable_names[1] <- "orig"
  variable_names[2] <- "dest"
  
  colnames(data_df) <- variable_names
  
  if(!missing(input_port_zone_vector)) {
    
    work_df <- 
      data_df %>%
      filter(orig %in% input_port_zone_vector | dest %in% input_port_zone_vector)
  
  } else {
    
    work_df <- data_df
    
  }
  
  work_df <- 
    data_df %>%
    filter(orig %in% input_port_zone_vector | dest %in% input_port_zone_vector)
  
  saveRDS(work_df, file = output_r_dataframe_file)
  
}


# -----------------------------------------------------------------------------------
# Helper Function to Read and Store (Trimmed) Trips and Skims
Read_Trips_And_Skims <- function(input_file_name_vector) {
  
  dataframe_list <- list(length(input_file_name_vector))
  for (index in 1:length(input_file_name_vector)) {
    
    temp_df <- readRDS(input_file_name_vector[index])
    dataframe_list[[index]] <- temp_df
    
  }
  
  return(dataframe_list)

}

# -----------------------------------------------------------------------------------
Compute_Utilities <- function(input_trips_df, value_of_time, input_true_if_initial) {
  
  # testing
  # input_trips_df <- work_df
  # or
  # input_trips_df <- working_trips_df
  # value_of_time <- ms_vot
  
  
  # cost in utils per cent
  K_COST <- K_PORT_TIME / value_of_time * 60 / 100
  
  work_df <- 
    input_trips_df %>%
    mutate(temp_utility = bias_constant + K_TRAVEL_TIME * orig_to_port_time + K_TRAVEL_TIME * port_to_dest_time) %>%
    mutate(temp_utility = temp_utility + K_COST * port_toll_cost)
  
  if (input_true_if_initial) {
    
    work_df <-
      work_df %>%
      mutate(utility = temp_utility) %>%
      select(-temp_utility)
    
  } else {
    
    work_df <-
      work_df %>%
      mutate(utility = ifelse(is.na(port_time), MISSING_UTILITY, temp_utility + K_PORT_TIME * port_time)) %>%
      select(-temp_utility)
    
  }
  
  work_df <- work_df %>%
    mutate(utility = ifelse(open_lanes == 0, MISSING_UTILITY, utility))
  
  return(work_df)
  
}

# -----------------------------------------------------------------------------------
# Port Choice (TODO: document properly)
Port_of_Entry_Choice_Initial <- function(input_trips_df_list, input_skims_df_list, input_port_configs_df, input_port_rates_df, input_vot_df) {
  
  # testing
  # input_trips_df_list <- trips_df_list
  # input_skims_df_list <- skims_df_list
  # input_port_configs_df <- port_configurations_df
  # input_port_rates_df <- port_entry_rates_df
  # input_vot_df <- value_of_time_df
  
  ALL_TRAVELER_TYPES <- "_All_"
  
  # maps of trip table names to vehicle_types and traveler_types
  vehicle_type <- c("Passenger", "Passenger", "Passenger", "Commercial", "Commercial")
  travel_purpose <- c("HBO", "HBW", "HBS", "Loaded", "Empty")
  vehicle_type_travel_purpose_map <- data.frame(vehicle_type, travel_purpose, stringsAsFactors = FALSE)
  remove(vehicle_type)
  
  traveler_type        <- c("FAST", "General", "General", "Ready", "SENTRI")
  traveler_type_signal <- c("FAST", "GP",      "General", "Ready", "SENTRI")
  traveler_type_map    <- data.frame(traveler_type, traveler_type_signal, stringsAsFactors = FALSE)
  remove(traveler_type, traveler_type_signal)
  
  DELIMITER <- "--"

  market_segments_vector <- 
    input_port_configs_df %>%
    mutate(market_segment = paste(port_name, direction, vehicle_type, traveler_type, port_zone, sep = DELIMITER)) %>%
    .$market_segment

  bias_constant_vector <- input_port_configs_df$port_choice_bias_constant
  port_toll_cost_vector <- input_port_configs_df$default_toll_in_dollars
  
  if (exists("across_hours_df")) remove(across_hours_df)
  for(hour_index in 1:24) {
    
    # testing
    # hour_index <- 1
    # print(paste0("Hour index: ", hour_index))
    
    # trips and skims
    trips_df <- input_trips_df_list[[hour_index]]
    skims_df <- input_skims_df_list[[hour_index]]
    
    # prepare OD trips
    gathered_trips_df <- 
      trips_df %>%
      gather(key = "table", value = "od_trips", -orig, -dest, -direction, na.rm = TRUE) %>%
      separate(table, into = c("travel_purpose", "traveler_type_signal"), sep = "_", remove = TRUE)
    
    gathered_trips_df <- left_join(gathered_trips_df, traveler_type_map, by = c("traveler_type_signal"))
    gathered_trips_df <- left_join(gathered_trips_df, vehicle_type_travel_purpose_map, by = c("travel_purpose"))
    
    hour_trips_df <- 
      gathered_trips_df %>%
      group_by(orig, dest, direction, vehicle_type, travel_purpose, traveler_type) %>%
      summarise(od_trips = sum(od_trips)) %>%
      ungroup()
    
    remove(gathered_trips_df, trips_df)
    
    if (exists("across_segments_df")) remove (across_segments_df)
    for (market_segment in market_segments_vector) {
      
      # testing
      # market_segment <- market_segments_vector[1]
      # print(paste0(market_segment))
      
      ms_port_name <- str_split(market_segment, DELIMITER)[[1]][1]
      ms_direction <- str_split(market_segment, DELIMITER)[[1]][2]
      ms_vehicle_type <- str_split(market_segment, DELIMITER)[[1]][3]
      ms_traveler_type <- str_split(market_segment, DELIMITER)[[1]][4]
      ms_port_zone <- as.numeric(str_split(market_segment, DELIMITER)[[1]][5])
      
      ms_bias_constant <- bias_constant_vector[which(market_segments_vector == market_segment)]
      ms_port_toll_cost <- port_toll_cost_vector[which(market_segments_vector == market_segment)]
      
      # join trips and skims
      market_segment_trips_df <- 
        hour_trips_df %>%
        filter(direction == ms_direction) %>%
        filter(vehicle_type == ms_vehicle_type)
      
      if (ms_traveler_type != ALL_TRAVELER_TYPES) {
        market_segment_trips_df <-
          market_segment_trips_df %>%
          filter(traveler_type == ms_traveler_type)
      } else {
        market_segment_trips_df <- 
          market_segment_trips_df %>%
          mutate(traveler_type = ms_traveler_type)
      }

      # for cases when there are multiple trip rows of same config
      market_segment_trips_df <- 
        market_segment_trips_df %>%
        group_by(orig, dest, direction, vehicle_type, travel_purpose, traveler_type) %>%
        summarise(od_trips = sum(od_trips)) %>%
        ungroup()
      
      market_segment_trips_df <- market_segment_trips_df %>%
        mutate(port_name = ms_port_name) %>%
        mutate(port_zone = ms_port_zone) %>%
        mutate(bias_constant = ms_bias_constant) %>%
        mutate(port_toll_cost = ms_port_toll_cost)
      
      join_skim <- 
        skims_df %>%
        select(orig, port_zone = dest, orig_to_port_time = Time)
      
      market_segment_trips_df <- left_join(market_segment_trips_df, join_skim, by = c("orig", "port_zone"))
      
      join_skim <- 
        skims_df %>%
        select(port_zone = orig, dest, port_to_dest_time = Time)
      
      market_segment_trips_df <- left_join(market_segment_trips_df, join_skim, by = c("port_zone", "dest"))
      
      # initialize port toll cost
      market_segment_trips_df <- 
        market_segment_trips_df %>%
        mutate(port_toll_cost = ms_port_toll_cost * 100.0)
      
      # adding open lanes information 
      ms_open_lanes <- input_port_rates_df %>% 
        filter(hour == hour_index,
               port_name == ms_port_name,
               direction == ms_direction,
               traveler_type == ms_traveler_type,
               vehicle_type == ms_vehicle_type) %>%
        .$open_lanes
      
      market_segment_trips_df <- market_segment_trips_df %>%
        mutate(open_lanes = ms_open_lanes)
      
      if (exists("across_purpose_df")) remove (across_purpose_df)
      for (ms_purpose in travel_purpose) {
        # testing 
        # ms_purpose <- "HBW"
        
        working_trips_df <- 
          market_segment_trips_df %>%
          filter(travel_purpose == ms_purpose)
        
        # get appropriate value of time
        ms_purpose_vot <- input_vot_df %>%
          filter(vehicle_type == ms_vehicle_type,
                 traveler_type == ms_traveler_type,
                 direction == ms_direction,
                 purpose == ms_purpose) %>%
          .$value_of_time_dollars
        
        # compute utility
        working_trips_df <- Compute_Utilities(working_trips_df, ms_purpose_vot, TRUE)
        
        working_trips_df <- 
          working_trips_df %>%
          mutate(exponentiated_utility = ifelse(utility < (MISSING_UTILITY + 10.0), 0, exp(utility))) %>%
          mutate(direction = ms_direction) %>%
          mutate(hour = hour_index)
        
        if (exists("across_purpose_df")) {
          across_purpose_df <- bind_rows(across_purpose_df, working_trips_df)
        } else {
          across_purpose_df <- working_trips_df
        }
        
      }  # for travel purpuse
      
      if (exists("across_segments_df")) {
        across_segments_df <- bind_rows(across_segments_df, across_purpose_df)
      } else {
        across_segments_df <- across_purpose_df
      }
      
    } # for market segment
    
    if (exists("across_hours_df")) {
      across_hours_df <- bind_rows(across_hours_df, across_segments_df)
    } else {
      across_hours_df <- across_segments_df
    }
    
  } # for hour
  
  # compute probabilities -- across hour, direction origin, destination, vehicle type, and traveler type
  return_df <- 
    across_hours_df %>%
    group_by(hour, direction, orig, dest, vehicle_type, travel_purpose, traveler_type) %>%
    mutate(probability = exponentiated_utility / sum(exponentiated_utility)) %>%
    ungroup() %>%
    mutate(probability = ifelse(is.nan(probability), 0.0, probability)) %>%
    mutate(trips = probability * od_trips) %>%
    arrange(hour, direction, vehicle_type, traveler_type, orig, dest, port_name)
  
  return(return_df)
  
} 

# -----------------------------------------------------------------------------------
Port_of_Entry_Choice_Update <- function(input_port_of_entry_demand_df, input_vot_df) {
  
  # testing
  # input_port_of_entry_demand_df <- port_of_entry_demand_df
  # input_vot_df <- value_of_time_df
  
  demand_df <- 
    input_port_of_entry_demand_df %>%
    select(-utility, -exponentiated_utility, -probability, -trips)
  
  DELIMITER <- "--"
  
  market_segments_vector <- 
    demand_df %>%
    mutate(market_segment = paste(vehicle_type, traveler_type, direction, sep = DELIMITER)) %>%
    .$market_segment
  
  market_segments_vector <- unique(market_segments_vector)
  
  travel_purpose <- c("HBO", "HBW", "HBS", "Loaded", "Empty")
  
  if (exists("across_segments_df")) remove (across_segments_df)
  
  for (market_segment in market_segments_vector) {
    # testing
    # market_segment <- market_segments_vector[1]
    # print(paste0(market_segment))
    
    ms_vehicle_type <- str_split(market_segment, DELIMITER)[[1]][1]
    ms_traveler_type <- str_split(market_segment, DELIMITER)[[1]][2]
    ms_direction <- str_split(market_segment, DELIMITER)[[1]][3]
    
    if (exists("across_purpose_df")) remove (across_purpose_df)
    for (ms_purpose in travel_purpose) {
      # testing 
      # ms_purpose <- "HBW"
      
      working_trips_df <- demand_df %>%
        filter(vehicle_type == ms_vehicle_type,
               traveler_type == ms_traveler_type,
               direction == ms_direction,
               travel_purpose == ms_purpose)
      
      # get appropriate value of time
      ms_purpose_vot <- input_vot_df %>%
        filter(vehicle_type == ms_vehicle_type,
               traveler_type == ms_traveler_type,
               direction == ms_direction,
               purpose == ms_purpose) %>%
        .$value_of_time_dollars
      
      working_trips_df <- Compute_Utilities(working_trips_df, ms_purpose_vot, FALSE)
      
      if (exists("across_purpose_df")) {
        across_purpose_df <- bind_rows(across_purpose_df, working_trips_df)
      } else {
        across_purpose_df <- working_trips_df
      }
      
    }  # for travel purpuse
    
    if (exists("across_segments_df")) {
      across_segments_df <- bind_rows(across_segments_df, across_purpose_df)
    } else {
      across_segments_df <- across_purpose_df
    }
    
  } # for market segments
  
  return_df <- 
    across_segments_df %>%
    mutate(exponentiated_utility = ifelse(utility < (MISSING_UTILITY + 10.0), 0, exp(utility))) %>%
    group_by(hour, direction, orig, dest, vehicle_type, travel_purpose, traveler_type) %>%
    mutate(probability = exponentiated_utility / sum(exponentiated_utility)) %>%
    ungroup() %>%
    mutate(probability = ifelse(is.nan(probability), 0.0, probability)) %>%
    mutate(trips = probability * od_trips) %>%
    arrange(hour, direction, vehicle_type, traveler_type, travel_purpose, orig, dest, port_name)
    
  return(return_df)
  
}

# -----------------------------------------------------------------------------------
Update_Port_Times <- function(input_port_of_entry_demand_df, input_des_outcomes_df){
  
  # testing
  # input_port_of_entry_demand_df <- port_of_entry_demand_df
  # input_des_outcomes_df <- des_outcomes_df
  
  join_des <- 
    input_des_outcomes_df %>%
    separate(config, into = c("port_name", "direction", "vehicle_type", "traveler_type"), sep = DELIMITER, remove = TRUE)
  
  join_poe <-
    input_port_of_entry_demand_df
  
  joined <- left_join(join_poe, join_des, by = c("hour", "port_name", "direction", "vehicle_type", "traveler_type"))
  
  joined <- 
    joined %>%
    mutate(port_time = median_wait_time + median_process_time) %>%
    select(-median_wait_time, -median_process_time, -queue)
  
  return(joined)
  
}


Add_Des_Times <- function(input_port_of_entry_demand_df, input_des_outcomes_df, input_des_name){
  join_des <- 
    input_des_outcomes_df %>%
    separate(config, into = c("port_name", "direction", "vehicle_type", "traveler_type"), sep = DELIMITER, remove = TRUE)
  
  joined <- left_join(input_port_of_entry_demand_df, join_des, by = c("hour", "port_name", "direction", "vehicle_type", "traveler_type"))
  
  joined[[input_des_name]] <- joined$median_wait_time + joined$median_process_time
  
  joined <- 
    joined %>%
    select(-median_wait_time, -median_process_time, -queue)
  
  return(joined)
  
}

# -----------------------------------------------------------------------------------
Update_Port_Toll_Costs <- function(input_port_of_entry_demand_df, input_port_entry_rates_df, input_min_toll_vector){
  
  # testing
  # input_port_of_entry_demand_df <- port_of_entry_demand_df
  # input_port_entry_rates_df <- port_entry_rates_df
  # input_min_toll_vector <- min_toll_vector
  
  nb_pov_min_toll <- input_min_toll_vector[["PV_NB_MIN_TOLL"]]
  sb_pov_min_toll <- input_min_toll_vector[["PV_SB_MIN_TOLL"]]
  nb_com_min_toll <- input_min_toll_vector[["CV_NB_MIN_TOLL"]]
  sb_com_min_toll <- input_min_toll_vector[["CV_SB_MIN_TOLL"]]
  
  work_des_outcomes_df <- (Discrete_Event_Simulation(input_port_entry_rates_df, input_port_of_entry_demand_df))$wait_times
  
  work_des_outcomes_df <- work_des_outcomes_df %>%
    separate(config, into = c("port_name", "direction", "vehicle_type", "traveler_type"), sep = DELIMITER, remove = TRUE)
  
  joined <- left_join(input_port_of_entry_demand_df, work_des_outcomes_df, by = c("hour", "port_name", "direction", "vehicle_type", "traveler_type"))
  
  # increasing or decreasing toll by 25 cents only 
  joined <- joined %>%
    filter(port_name == OTAY_MESA_EAST_NAME) %>%
    group_by(hour, port_name, vehicle_type, direction) %>%
    summarise(max_wait_time = max(median_wait_time), prev_port_toll = mean(port_toll_cost)) %>%
    mutate(new_port_toll = ifelse(max_wait_time > 20.0, prev_port_toll + 25.00, prev_port_toll)) %>%
    mutate(new_port_toll = ifelse(max_wait_time < 20.0, new_port_toll - 25.00, new_port_toll)) %>%
    mutate(new_port_toll = ifelse(vehicle_type == "Passenger" & direction == "Northbound" & new_port_toll < nb_pov_min_toll, nb_pov_min_toll, new_port_toll)) %>%
    mutate(new_port_toll = ifelse(vehicle_type == "Passenger" & direction == "Southbound" & new_port_toll < sb_pov_min_toll, sb_pov_min_toll, new_port_toll)) %>%
    mutate(new_port_toll = ifelse(vehicle_type == "Commercial" & direction == "Northbound" & new_port_toll < nb_com_min_toll, nb_com_min_toll, new_port_toll)) %>%
    mutate(new_port_toll = ifelse(vehicle_type == "Commercial" & direction == "Southbound" & new_port_toll < sb_com_min_toll, sb_com_min_toll, new_port_toll)) %>%
    select(-c(max_wait_time, prev_port_toll))
  
  return_df <- left_join(input_port_of_entry_demand_df, joined, by = c("hour", "port_name", "vehicle_type", "direction")) %>%
    replace_na(list(new_port_toll = 0)) %>%
    mutate(port_toll_cost = new_port_toll) %>%
    select(-new_port_toll)
  
  return(return_df)
  
}

Create_Trace_Log <- function(input_port_of_entry_demand, input_iter, input_otaz, input_dtaz, input_hour, input_vehicle_type, input_direction, input_traveler_type){
  # testing
  #input_port_of_entry_demand <- port_of_entry_demand_df
  #input_iter <- iterations  
  #input_otaz <- trace_otaz
  #input_dtaz <- trace_dtaz
  #input_hour <- trace_hour
  #input_vehicle_type <- trace_vehicle_type
  #input_direction <- trace_direction
  #input_traveler_type <- trace_traveler_type
  
  work_df <- input_port_of_entry_demand %>%
    filter(orig == input_otaz,
           dest == input_dtaz,
           hour == input_hour,
           direction == input_direction,
           vehicle_type == input_vehicle_type,
           traveler_type == input_traveler_type
    )
  
  if(nrow(work_df) > 0){
    log <- ""
    
    if(input_iter == 1){
      log <- paste0(log, "######################################", "\n")
      log <- paste0(log, "Orig: ", input_otaz, "\n")
      log <- paste0(log, "Dest: ", input_dtaz, "\n")
      log <- paste0(log, "Hour: ", input_hour, "\n")
      log <- paste0(log, "Vehicle Type: ", input_vehicle_type, "\n")
      log <- paste0(log, "Direction: ", input_direction, "\n")
      log <- paste0(log, "Traveler Type: ", input_traveler_type, "\n")
      log <- paste0(log, "\n")
      log <- paste0(log, "Total Trips: ", round(work_df$od_trips[1],2), "\n")
      log <- paste0(log, "\n")
      log <- paste0(log, "######################################", "\n")
      log <- paste0(log, "\n")
    }
    
    log <- paste0(log, "--------------------------------------", "\n")
    log <- paste0(log, "ITERATION: ", input_iter, "\n")
    
    port_vector <- work_df$port_name
    
    for(port in port_vector){
      port_df <- work_df %>% filter(port_name == port)
      port_constant <- port_df$bias_constant
      port_toll_cost <- port_df$port_toll_cost
      orig_to_port_time <- port_df$orig_to_port_time
      port_to_dest_time <- port_df$port_to_dest_time
      port_time <- port_df$port_time
      port_utility <- port_df$utility
      port_exp_utility <- port_df$exponentiated_utility
      port_probability <- port_df$probability
      port_trips <- port_df$trips
      
      log <- paste0(log, port, "\n")
      log <- paste0(log, "\t", "Port Constant: ", port_constant, "\n")
      log <- paste0(log, "\t", "Port Cost: ", port_toll_cost, "\n")
      log <- paste0(log, "\t", "Orig to Port Time: ", orig_to_port_time, "\n")
      log <- paste0(log, "\t", "Port to Dest Time: ", port_to_dest_time, "\n")
      log <- paste0(log, "\t", "Port Time: ", port_time, "\n")
      log <- paste0(log, "\t", "Utility: ", port_utility, "\n")
      log <- paste0(log, "\t", "Exp Utility: ", port_exp_utility, "\n")
      log <- paste0(log, "\t", "Probability: ", port_probability, "\n")
      log <- paste0(log, "\t", "Trips: ", port_trips, "\n")
    }
    
    log <- paste0(log, "--------------------------------------", "\n")

  }
  else {
    if(input_iter == 1){
      log <- paste0("There is no data corresponding to specified trace options. Please check the trace parameters again!")
    }
    else {
      log <- NULL
    }
  }
  
  return(log)
}

Source_Partial <- function(fn,startTag='#calibration from here',endTag='#calibration to here') {
  lines <- scan(fn, what=character(), sep="\n", quiet=TRUE)
  st<-grep(startTag,lines)
  en<-grep(endTag,lines)
  tc <- textConnection(lines[(st+1):(en-1)])
  source(tc)
  close(tc)
}

Get_Tolls <- function(input_demand_df) {
  # input_demand_df <- port_of_entry_demand_df
  
  toll_values <- 
    input_demand_df %>%
    group_by(hour, vehicle_type, direction) %>% 
    summarise(toll_in_cents = max(port_toll_cost)) %>% 
    arrange(vehicle_type, direction) %>%
    mutate(type = case_when(
      vehicle_type == "Passenger" & direction == "Northbound" ~ "PV_NB",
      vehicle_type == "Passenger" & direction == "Southbound" ~ "PV_SB",
      vehicle_type == "Commercial" & direction == "Northbound" ~ "CV_NB",
      vehicle_type == "Commercial" & direction == "Southbound" ~ "CV_SB",
      TRUE ~ "OTHER")
    ) %>% 
    as.data.frame() %>%
    select(hour, type, toll_in_cents) %>%
    spread(type, toll_in_cents)
  
  return(toll_values)  
}
