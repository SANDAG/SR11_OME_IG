SENTRI_NAME <- "SENTRI"
GENERAL_NAME <- "General"
MAX_GEN_WAIT <- 120

# -----------------------------------------------------------------------------------
Update_Lane_Configuration <- function(input_port_rates_df, input_port_of_entry_demand_df, input_min_toll_vector) {
  # testing
  # input_port_of_entry_demand_df <- port_of_entry_demand_df
  # input_port_rates_df <- port_entry_rates_df
  # input_min_toll_vector <- min_toll_vector
  
  print("   Updating Lanes Configuration ... ")
  
  input_port_rates_df <- 
    input_port_rates_df %>%
    replace_na(list(gp_re_max = 9999))
    
  configuration_vector <- 
    input_port_rates_df %>%
    mutate(bundle = paste0(port_name, DELIMITER, direction, DELIMITER, vehicle_type)) %>%
    distinct(bundle) %>%
    .$bundle
  
  #toll_equal_to_default = TRUE
  
  nb_pov_min_toll <- input_min_toll_vector[["PV_NB_MIN_TOLL"]]
  sb_pov_min_toll <- input_min_toll_vector[["PV_SB_MIN_TOLL"]]
  nb_com_min_toll <- input_min_toll_vector[["CV_NB_MIN_TOLL"]]
  sb_com_min_toll <- input_min_toll_vector[["CV_SB_MIN_TOLL"]]
  
  input_toll_df <- 
    input_port_of_entry_demand_df %>%
    group_by(vehicle_type, direction, hour) %>%
    summarise(toll_in_cents = max(port_toll_cost)) %>%
    mutate(min_toll = 
             case_when(vehicle_type == "Passenger" & direction == "Northbound" ~ nb_pov_min_toll,
                       vehicle_type == "Passenger" & direction == "Southbound" ~ sb_pov_min_toll,
                       vehicle_type == "Commercial" & direction == "Northbound" ~ nb_com_min_toll,
                       vehicle_type == "Commercial" & direction == "Southbound" ~ sb_com_min_toll,
                       TRUE ~ 0)
           ) %>%
    mutate(toll_equal_min = toll_in_cents == min_toll)
  
  #nb_pov_current_toll <- input_toll_df %>% filter(vehicle_type == "Passenger", direction == "Northbound") %>% .$toll_in_cents
  #sb_pov_current_toll <- input_toll_df %>% filter(vehicle_type == "Passenger", direction == "Southbound") %>% .$toll_in_cents
  #nb_com_current_toll <- input_toll_df %>% filter(vehicle_type == "Commercial", direction == "Northbound") %>% .$toll_in_cents
  #sb_com_current_toll <- input_toll_df %>% filter(vehicle_type == "Commercial", direction == "Southbound") %>% .$toll_in_cents
  
  if (exists("return_df")) remove (return_df)
  
  # Update lanes for each configuration
  for (configuration in configuration_vector) {
    # testing
    #configuration <- configuration_vector[2]
    #print(paste0("Allocating Lanes for ... ", configuration))

    config_port_name <- str_split(configuration, DELIMITER)[[1]][1]
    config_direction <- str_split(configuration, DELIMITER)[[1]][2]
    config_vehicle_type <- str_split(configuration, DELIMITER)[[1]][3]
    
    config_port_of_entry_demand_df <- 
      input_port_of_entry_demand_df %>%
      filter(port_name == config_port_name) %>%
      filter(direction == config_direction) %>%
      filter(vehicle_type == config_vehicle_type)
    
    config_port_rates_df <-
      input_port_rates_df %>%
      filter(port_name == config_port_name) %>%
      filter(direction == config_direction) %>%
      filter(vehicle_type == config_vehicle_type)
    
    toll_equal_to_default <- rep(TRUE, 24)
    
    #if(config_direction == "Northbound" & config_vehicle_type == "Passenger" & nb_pov_current_toll > nb_pov_min_toll)
    #  toll_equal_to_default <- FALSE
    #
    #if(config_direction == "Southbound" & config_vehicle_type == "Passenger" & sb_pov_current_toll > sb_pov_min_toll)
    #  toll_equal_to_default <- FALSE
    #
    #if(config_direction == "Northbound" & config_vehicle_type == "Commercial" & nb_com_current_toll > nb_com_min_toll)
    #  toll_equal_to_default <- FALSE
    #
    #if(config_direction == "Southbound" & config_vehicle_type == "Commercial" & sb_com_current_toll > sb_com_min_toll)
    #  toll_equal_to_default <- FALSE
    
    MAX_LANE_UPDATE_ITERS <- 1
    iteration <- 0
    converged <- FALSE
    
    while(!converged & iteration < MAX_LANE_UPDATE_ITERS){
      iteration <- iteration + 1
      
      # check if Sentri lane persent for the configuration
      sentri_lanes_present <- SENTRI_NAME %in% config_port_of_entry_demand_df$traveler_type
      
      # reallocate sentri lanes first, if present
      if (sentri_lanes_present) {
        
        sentri_port_demand_df <- 
          config_port_of_entry_demand_df %>%
          filter(traveler_type == SENTRI_NAME)
        
        min_general_lanes <- config_port_rates_df %>% filter(traveler_type == "General") %>% .$min_lanes
        min_ready_lanes <- config_port_rates_df %>% filter(traveler_type == "Ready") %>% .$min_lanes
        
        sentri_port_rates_df <- 
          config_port_rates_df %>%
          filter(traveler_type == SENTRI_NAME) %>%
          mutate(max_available_lanes = max_lanes - min_general_lanes - min_ready_lanes)

        sentri_port_rates_df <- Allocate_Lanes(sentri_port_demand_df, sentri_port_rates_df, toll_equal_to_default)
        
        sentri_lanes_df <-
          sentri_port_rates_df %>%
          mutate(sentri_lanes = open_lanes) %>%
          select(hour, port_name, direction, vehicle_type, sentri_lanes)
      }
      
      # toll constraint should only used as flag when updating lanes for OME
      # also, SENTRI does not look at toll to 'close a lane', so the SENTRI flag was still set at TRUE even for OME.
      if(config_port_name == OTAY_MESA_EAST_NAME){  
        toll_equal_to_default <- input_toll_df %>% 
          as.data.frame() %>%
          filter(vehicle_type == config_vehicle_type, direction == config_direction) %>% 
          select(hour, toll_equal_min) %>%
          complete(hour=1:24) %>%
          mutate(toll_equal_min = ifelse(is.na(toll_equal_min), TRUE, toll_equal_min)) %>%
          .$toll_equal_min
      }
      
      # reallocate other lane types
      remainder_port_of_entry_demand_df <- 
        config_port_of_entry_demand_df %>%
        filter(traveler_type != SENTRI_NAME)
      
      remainder_port_rates_df <- 
        config_port_rates_df %>%
        filter(traveler_type != SENTRI_NAME) 
      
      if (sentri_lanes_present) {
        remainder_port_rates_df <- left_join(remainder_port_rates_df, sentri_lanes_df, by = c("hour", "port_name", "direction", "vehicle_type"))
      } else {
        remainder_port_rates_df <- remainder_port_rates_df %>% mutate(sentri_lanes = 0)
      }
      
      remainder_port_rates_df <- remainder_port_rates_df %>%
        mutate(max_available_lanes = max_lanes - sentri_lanes) %>%
        select(-sentri_lanes) %>%
        mutate(max_available_lanes = pmin(max_available_lanes, gp_re_max))
      
      remainder_config <- sort(unique(remainder_port_rates_df$traveler_type))
      
      # initialize output array
      config_final_rates_df <- 
        remainder_port_rates_df %>%
        slice(0:0)
      
      for (config in remainder_config) {
        #config <- remainder_config[1]
        c_port_demand_df <- 
          remainder_port_of_entry_demand_df %>%
          filter(traveler_type == config)
        
        c_port_rates_df <- 
          remainder_port_rates_df %>%
          filter(traveler_type == config)
        
        c_port_rates_df <- Allocate_Lanes(c_port_demand_df, c_port_rates_df, toll_equal_to_default)
        config_final_rates_df <- rbind(config_final_rates_df, c_port_rates_df)
      }

      config_final_rates_df <- Balance_Lanes(remainder_port_of_entry_demand_df, config_final_rates_df)
      
      if (sentri_lanes_present)
        config_final_rates_df <- bind_rows(sentri_port_rates_df, config_final_rates_df)
      
      # check convergence
      # if there is no change in open lanes and stacked lanes from previous iteration
      # configuration lane allocation is converged
      prior_lanes <- config_port_rates_df %>% 
        select(hour, port_name, traveler_type, vehicle_type, direction, prior_open_lanes = open_lanes, prior_stacked_lanes = stacked_lanes)
      
      joined <- left_join(config_final_rates_df, prior_lanes, by = c("hour", "port_name", "traveler_type", "vehicle_type", "direction"))
      
      joined <- joined %>%
        mutate(changed = ifelse(open_lanes == prior_open_lanes & stacked_lanes == prior_stacked_lanes, 0, 1))
      
      converged <- sum(joined$changed) == 0

      config_port_rates_df <- config_final_rates_df
      
    }
    
    if (exists("return_df")) {
      return_df <- bind_rows(return_df, config_final_rates_df)
    } else {
      return_df <- config_final_rates_df
    }

  } # for configuration
  
  return_df <- return_df %>% 
    mutate(gp_re_max = ifelse(gp_re_max == 9999, NA, gp_re_max)) %>%
    select(-max_available_lanes) %>% 
    arrange(hour)
  
  return(return_df)
}


# -----------------------------------------------------------------------------------
Allocate_Lanes <- function(input_demand_df, input_rates_df, input_toll_equal_to_default) {
  #input_demand_df <- sentri_port_demand_df
  #input_rates_df <- sentri_port_rates_df
  
  #input_demand_df <- c_port_demand_df
  #input_rates_df <- c_port_rates_df
  
  #input_toll_equal_to_default <- toll_equal_to_default
  
  MAX_ITERATIONS <- 10
  iteration <- 0
  change_needed <- TRUE
  
  # if the toll for that hour is equal to minimum and the wait time is less than min wait time, we close a lane
  # if the toll is greater than minimum and the wait time is less than min wait time, we dont close a lane, instead toll should be decreased in toll update routine. 
  
  # wait time is lower than min wait
  while (iteration < MAX_ITERATIONS & change_needed) {
    iteration <- iteration + 1
    #print(paste0("allocate iteration ", iteration))
    
    work_des_outcomes_df <- (Discrete_Event_Simulation(input_rates_df, input_demand_df))$wait_times
    
    work_des_outcomes_df <- work_des_outcomes_df %>%
      separate(config, into = c("port_name", "direction", "vehicle_type", "traveler_type"), sep = DELIMITER, remove = TRUE)
    
    joined_df <- left_join(input_rates_df, work_des_outcomes_df, by = c("hour", "port_name", "direction", "vehicle_type", "traveler_type"))
    
    joined_df <- joined_df %>%
      mutate(toll_is_min = input_toll_equal_to_default)
    
    assessment_per_hour_df <-
      joined_df %>%
      mutate(zero_stacked_lanes = ifelse(allow_stack == 1 & stacked_lanes > 0, FALSE, TRUE)) %>%
      mutate(new_stacked_lanes = ifelse(median_wait_time < min_wait & open_lanes > min_lanes & !zero_stacked_lanes & toll_is_min, stacked_lanes - inc_lanes, stacked_lanes)) %>%
      mutate(new_open_lanes = ifelse(median_wait_time < min_wait & open_lanes > min_lanes & zero_stacked_lanes & toll_is_min, open_lanes - inc_lanes, open_lanes)) %>%
      mutate(problem = ifelse(new_open_lanes == open_lanes & new_stacked_lanes == stacked_lanes, 0, 1)) 
    
    change_needed <- sum(assessment_per_hour_df$problem) > 0
    
    input_rates_df <- 
      assessment_per_hour_df %>%
      select(hour, port_name, traveler_type, vehicle_type, max_lanes, open_lanes = new_open_lanes, stacked_lanes = new_stacked_lanes,
             stacked_rate, process_rate, gp_re_max, min_lanes, inc_lanes, allow_stack, min_wait, max_wait, balance_factor, direction, max_available_lanes) %>% 
      as.data.frame()
  }
  
  MAX_ITERATIONS <- 10
  iteration <- 0
  change_needed <- TRUE
  
  # wait time is greater than max wait
  while (iteration < MAX_ITERATIONS & change_needed) {
    iteration <- iteration + 1
    #print(paste0("iteration ", iteration))
    
    work_des_outcomes_df <- (Discrete_Event_Simulation(input_rates_df, input_demand_df))$wait_times
    
    work_des_outcomes_df <- work_des_outcomes_df %>%
      separate(config, into = c("port_name", "direction", "vehicle_type", "traveler_type"), sep = "--", remove = TRUE)
    
    joined_df <- left_join(input_rates_df, work_des_outcomes_df, by = c("hour", "port_name", "direction", "vehicle_type", "traveler_type"))
    
    assessment_per_hour_df <-
      joined_df %>%
      mutate(lane_constraint = ifelse(open_lanes >= max_available_lanes & stacked_lanes == allow_stack * open_lanes, TRUE, FALSE)) %>%
      mutate(new_open_lanes = ifelse(median_wait_time > max_wait & !lane_constraint, open_lanes + inc_lanes, open_lanes)) %>%
      mutate(new_stacked_lanes = ifelse(median_wait_time > max_wait & !lane_constraint & open_lanes >= max_available_lanes & allow_stack == 1, stacked_lanes + inc_lanes, stacked_lanes)) %>%
      mutate(problem = ifelse(new_open_lanes == open_lanes & new_stacked_lanes == stacked_lanes, 0, 1))
  
    change_needed <- sum(assessment_per_hour_df$problem) > 0
    
    input_rates_df <- 
      assessment_per_hour_df %>%
      select(hour, port_name, traveler_type, vehicle_type, max_lanes, open_lanes = new_open_lanes, stacked_lanes = new_stacked_lanes,
             stacked_rate, process_rate, gp_re_max, min_lanes, inc_lanes, allow_stack, min_wait, max_wait, balance_factor, direction, max_available_lanes) %>% 
      as.data.frame()
  }
  
  return(input_rates_df)  
}

# -----------------------------------------------------------------------------------
Balance_Lanes <- function(input_demand_df, input_rates_df){
  #testing
  #input_demand_df <- remainder_port_of_entry_demand_df
  #input_rates_df <- config_final_rates_df

  # no balancing for single traveler type, e.g., Southbound
  if(length(unique(input_rates_df$traveler_type)) == 1){
    return(input_rates_df)  
  }
  
  # Balancing is done for Northbound-Passenger General and Ready Lanes
  # or for Northbound-Commerical General and Special Lanes
  
  # because the 'general' and 'other' lane were reallocated seperately,
  # if new sum total of 'general' and 'other' lanes comes out greater than the available total lanes 
  # then the 'general' and 'other' lanes are reduced proportionaly to match the available total lanes
  
  aggregated_outcome_df <- input_rates_df %>%
    group_by(hour, port_name, direction, vehicle_type) %>%
    summarise(needed_lanes = sum(open_lanes), max_available_lanes = mean(max_available_lanes)) %>%
    mutate(problem = needed_lanes > max_available_lanes) %>% 
    select(-max_available_lanes)
  
  work_port_rates_df <- left_join(input_rates_df, aggregated_outcome_df, by = c("hour", "port_name", "direction", "vehicle_type"))

  general_port_rates_df <- work_port_rates_df %>%
    filter(traveler_type == GENERAL_NAME) %>% arrange(hour) %>%
    mutate(new_open_lanes = ifelse(problem, round(open_lanes * max_available_lanes/needed_lanes, 0), open_lanes)) %>%
    mutate(new_stacked_lanes = ifelse(problem & new_open_lanes < stacked_lanes, new_open_lanes, stacked_lanes))
  
  other_port_rates_df <- work_port_rates_df %>%
    filter(traveler_type != GENERAL_NAME) %>% arrange(hour) %>%
    mutate(new_open_lanes = ifelse(problem, max_available_lanes - general_port_rates_df$new_open_lanes, open_lanes)) %>%
    mutate(new_stacked_lanes = ifelse(problem & new_open_lanes < stacked_lanes, new_open_lanes, stacked_lanes))
  
  work_port_rates_df <- bind_rows(general_port_rates_df, other_port_rates_df)
  
  work_port_rates_df <- work_port_rates_df %>%
    select(hour, port_name, traveler_type, vehicle_type, max_lanes, open_lanes = new_open_lanes, stacked_lanes = new_stacked_lanes,
         stacked_rate, process_rate, gp_re_max, min_lanes, inc_lanes, allow_stack, min_wait, max_wait, balance_factor, direction, max_available_lanes)
  
  allow_stack <- as.logical(work_port_rates_df$allow_stack[1])
    
  # because the 'general' and 'other' open_lanes have changed, 
  # the wait times may no longer be less than the maximum wait time.
  # try to convert the new open general/other lanes to stacked lane to bring wait time below maximum wait time
  if (allow_stack)
    work_port_rates_df <- Update_Stacked_Lanes(work_port_rates_df, input_demand_df)

  # balance between GP and RE/SP
  MAX_ITERATIONS <- 10
  iteration <- 0
  change_needed <- TRUE
  
  while (iteration < MAX_ITERATIONS & change_needed) {
    iteration <- iteration + 1
    
    # see if there is an opportunity to reduce Ready/Special lane wait time further
    # by taking away a lane from General, if possible
    results <- Take_Lane_From_General(work_port_rates_df, input_demand_df)
    change_needed <- results$status
    work_port_rates_df <- results$rates_df
    
    # stacked and regular lanes are re-calculated using new open_lanes
    if (allow_stack)
      work_port_rates_df <- Update_Stacked_Lanes(work_port_rates_df, input_demand_df)
  }

  return(work_port_rates_df)
  
}

# -----------------------------------------------------------------------------------
# update stacked lanes , if possible (i.e., wait > max_wait and stacked_lanes < open_lanes)
Update_Stacked_Lanes <- function(input_rates_df, input_demand_df) {
  MAX_ITERATIONS <- 10
  iteration <- 0
  change_needed <- TRUE
  work_rates_df <- input_rates_df
  
  while (iteration < MAX_ITERATIONS & change_needed) {
    iteration <- iteration + 1
    #print(paste0("stacked lane iteration ", iteration))
    work_des_outcomes_df <- (Discrete_Event_Simulation(work_rates_df, input_demand_df))$wait_times
    
    work_des_outcomes_df <- work_des_outcomes_df %>%
      separate(config, into = c("port_name", "direction", "vehicle_type", "traveler_type"), sep = DELIMITER, remove = TRUE)
    
    joined_df <- left_join(work_rates_df, work_des_outcomes_df, by = c("hour", "port_name", "direction", "vehicle_type", "traveler_type"))
    
    joined_df <- joined_df %>%
      mutate(new_stacked_lanes = ifelse(median_wait_time > max_wait & stacked_lanes < allow_stack * open_lanes, stacked_lanes + inc_lanes, stacked_lanes)) %>%
      mutate(problem = ifelse(new_stacked_lanes == stacked_lanes, 0, 1))
    
    change_needed <- sum(joined_df$problem) > 0
    
    work_rates_df <- 
      joined_df %>%
      select(hour, port_name, traveler_type, vehicle_type, max_lanes, open_lanes, stacked_lanes = new_stacked_lanes,
             stacked_rate, process_rate, gp_re_max, min_lanes, inc_lanes, allow_stack, min_wait, max_wait, balance_factor, direction, max_available_lanes) %>% 
      as.data.frame() 
  }
  
  return(work_rates_df)
}

# -----------------------------------------------------------------------------------
# take one lane from general (if possible) and give it to other lane type
Take_Lane_From_General <- function(input_rates_df, input_demand_df) {
  # testing
  # input_rates_df <- work_port_rates_df 
  
  counter <- 0
  
  change_lane <- TRUE

  # this is done for one hour at a time, instead of doing for all 24 hours at the same time
  # as changing lanes in hour 1 changes things in hour 2
  
  for(input_hour in 1:24){
    # only if the lanes changed for previous hour, we run DES again. 
    if(change_lane) {
      work_des_outcomes_df <- (Discrete_Event_Simulation(input_rates_df, input_demand_df))$wait_times 
      
      work_des_outcomes_df <- work_des_outcomes_df %>%
        separate(config, into = c("port_name", "direction", "vehicle_type", "traveler_type"), sep = DELIMITER, remove = TRUE)
      
      joined_df <- left_join(input_rates_df, work_des_outcomes_df, by = c("hour", "port_name", "direction", "vehicle_type", "traveler_type")) %>%
        mutate(balance_times_wait = balance_factor*median_wait_time)
    }
    
    hour_joined_df <- joined_df %>% filter(hour == input_hour)
    other_joined_df <- joined_df %>% filter(hour != input_hour)
    
    general_values <- hour_joined_df %>% filter(traveler_type == GENERAL_NAME)
    other_values <- hour_joined_df %>% filter(traveler_type != GENERAL_NAME)
      
    change_lane <- FALSE
    if(general_values$median_wait_time < MAX_GEN_WAIT & general_values$open_lanes > general_values$min_lanes & 
       other_values$balance_times_wait > general_values$balance_times_wait) change_lane = TRUE
    
    if(change_lane){
      hour_joined_df <- hour_joined_df %>%
        mutate(open_lanes = case_when(
          traveler_type == GENERAL_NAME ~ open_lanes - inc_lanes,
          traveler_type != GENERAL_NAME ~ open_lanes + inc_lanes,
          TRUE ~ open_lanes)
        ) %>%
        mutate(stacked_lanes = case_when(
          (traveler_type == GENERAL_NAME & stacked_lanes > 0) ~ stacked_lanes - inc_lanes,
          TRUE ~ stacked_lanes)
        )
      
      input_rates_df <- bind_rows(hour_joined_df, other_joined_df) %>%
        select(-c(median_wait_time, median_process_time, queue, balance_times_wait)) %>%
        arrange(traveler_type)
      
      counter <- counter + 1
    }
    
  }

  results <- list()
  results$status <- counter > 0
  results$rates_df <- input_rates_df
  
  return(results) 
}

# -----------------------------------------------------------------------------------
# Reformat Port of Entry Rates file
Reformat_Port_of_Entry_Rates <- function(input_port_of_entry_rates_file, input_port_configurations_df) {
  
  # cross walks
  traveler_type_abbr <- c("GB", "SB", "SP", "RE", "GP", "SE")
  traveler_type <- c("General", "Southbound", "FAST", "Ready", "General", "SENTRI")
  traveler_type_df <- data.frame(traveler_type_abbr, traveler_type, stringsAsFactors = FALSE)
  remove(traveler_type_abbr, traveler_type)
  
  port_name_abbr <- c("SY", "OM", "OMC", "OME", "OMEC")
  port_name <- c("San Ysidro", "Otay Mesa", "Otay Mesa", "Otay Mesa East", "Otay Mesa East")
  vehicle_type <- c("Passenger", "Passenger", "Commercial", "Passenger", "Commercial")
  port_name_df <- data.frame(port_name_abbr, port_name, vehicle_type, stringsAsFactors = FALSE)
  remove(port_name, port_name_abbr)
  
  # Part 1: Add in port parameters parameters
  keys <- c("SY_GP","SY_RE","SY_SE","SY_SB",
           "OM_GP","OM_RE","OM_SE","OM_SB",
           "OMC_GP","OMC_SP","OMC_SB",
           "OME_GP","OME_RE","OME_SE","OME_SB",
           "OMEC_GP","OMEC_SP","OMEC_SB")
  
  min_lanes <- input_port_configurations_df$min_lanes
  inc_lanes <- input_port_configurations_df$inc_lanes
  allow_stack <- input_port_configurations_df$allow_stack
  min_wait <- input_port_configurations_df$min_wait
  max_wait <- input_port_configurations_df$max_wait
  balance_factor <- input_port_configurations_df$balance_factor
  
  parameters_df <- data.frame(keys, min_lanes, inc_lanes, allow_stack, min_wait, max_wait, balance_factor, stringsAsFactors = FALSE)
  
  parameters_df <- 
    parameters_df %>%
    separate(keys, into = c("port_name_abbr", "traveler_type_abbr"), sep = "_", remove = TRUE)
  
  parameters_df <- left_join(parameters_df, port_name_df, by = c("port_name_abbr"))
  parameters_df <- left_join(parameters_df, traveler_type_df, by = c("traveler_type_abbr"))
  parameters_df <-
    parameters_df %>%
    select(-port_name_abbr, -traveler_type_abbr)
  
  remove(keys, min_lanes, inc_lanes, allow_stack, min_wait, max_wait, balance_factor)

  # Part 2: Convert input file
  input_df <- read.csv(input_port_of_entry_rates_file, header = TRUE, stringsAsFactors = FALSE)

  work_df <- 
    input_df %>%
    select(-c(ends_with("GP_RE_MAX", ignore.case = TRUE))) %>%
    gather(key = "config_code", value = "value", -TIME) %>%
    separate(config_code, into = c("port_name_abbr", "traveler_type_abbr", "measure"), sep = "_", remove = FALSE)
  
  work_df <- left_join(work_df, traveler_type_df, by = c("traveler_type_abbr"))
  work_df <- left_join(work_df, port_name_df, by = c("port_name_abbr"))
  
  work_df <- 
    work_df %>%
    select(hour = TIME, port_name, traveler_type, vehicle_type, measure, measure_value = value) %>%
    spread(key = measure, value = measure_value) %>%
    select(hour, port_name, traveler_type, vehicle_type, max_lanes = MAX, open_lanes = OPEN, stacked_lanes = STL, 
           stacked_rate = STV, process_rate = VEH)
  
  gp_re_max_df <- input_df %>%
    select(TIME, ends_with("GP_RE_MAX", ignore.case = TRUE)) %>%
    gather(key = "config_code", value = "value", -TIME) %>%
    separate(config_code, into = c("port_name_abbr", "gp_abbr", "re_abbr", "measure"), sep = "_", remove = FALSE)
  
  gp_re_max_df <- left_join(gp_re_max_df, port_name_df, by = c("port_name_abbr")) %>%
    select(hour = TIME, port_name, vehicle_type, gp_re_max = value)
  
  work_df <- left_join(work_df, gp_re_max_df, by = c("hour", "port_name", "vehicle_type")) %>%
    mutate(gp_re_max = ifelse((traveler_type == "General" | traveler_type == "Ready"), gp_re_max, NA))
  
  poe_rates_df <- left_join(work_df, parameters_df, by = c("port_name", "traveler_type", "vehicle_type"))
  
  poe_rates_df <-
    poe_rates_df %>%
    mutate(direction = "Northbound") %>%
    mutate(direction = ifelse(traveler_type == "Southbound", traveler_type, direction)) %>%
    mutate(traveler_type = ifelse(direction == "Northbound", traveler_type, "_All_"))
  
  return(poe_rates_df)
  
}


Compute_Weighted_Average_Wait_Time <- function(input_des_outcomes_df, input_prior_des_outcomes_df, input_prior_weight) {
  
  join_prior <-
    input_prior_des_outcomes_df %>%
    select(hour, config, prior_wait = median_wait_time, prior_process = median_process_time)
  
  joined <- left_join(join_prior, input_des_outcomes_df, by = c("hour", "config"))
  
  return_df <- 
    joined %>%
    mutate(median_wait_time = median_wait_time * (1 - input_prior_weight) + prior_wait * input_prior_weight) %>%
    mutate(median_process_time = median_process_time * (1 - input_prior_weight) + prior_process * input_prior_weight) %>%
    select(hour, config, median_wait_time, median_process_time, queue)
  
  return(return_df)
  
}

# -----------------------------------------------------------------------------------
# Check convergence method
Check_Convergence <- function(input_des_outcomes_df, input_prior_des_outcomes_df) {
  
  # testing
  # input_des_outcomes_df <- des_outcomes_df
  # input_prior_des_outcomes_df <- prior_des_outcomes_df
  
  THRESHOLD <- 0.5
  
  join_prior <-
    input_prior_des_outcomes_df %>%
    select(hour, config, prior_wait = median_wait_time, prior_process = median_process_time)
  
  joined <- left_join(join_prior, input_des_outcomes_df, by = c("hour", "config"))
  
  tenth_error <- 
    joined %>%
    mutate(wait_error = abs(median_wait_time - prior_wait)) %>%
    mutate(process_error = abs(median_process_time - prior_process)) %>%
    arrange(-wait_error) %>%
    slice(10:10) %>%
    .$wait_error
  
  return(tenth_error < THRESHOLD)
  
}

# -----------------------------------------------------------------------------------
Update_Port_Arrivals <- function(input_des_inputs_df, input_port_of_entry_demand_df){
  
  # testing
  # input_des_inputs_df <- prior_des_inputs_df
  # input_port_of_entry_demand_df <- port_of_entry_demand_df
  
  join_poe <- 
    input_port_of_entry_demand_df %>%
    group_by(hour, port_name, direction, vehicle_type, traveler_type) %>%
    summarise(arrivals = sum(trips)) %>%
    ungroup() %>%
    mutate(arrivals = ifelse(is.na(arrivals), 0L, arrivals))
  
  join_des <- 
    input_des_inputs_df %>%
    mutate(hour = HOUR)
  
  joined <- left_join(join_des, join_poe, by = c("hour", "port_name", "direction", "vehicle_type", "traveler_type"))
  
  joined <- 
    joined %>%
    mutate(VEH_ARRIVAL = ifelse(is.na(arrivals), 0L, arrivals)) %>%
    select(-hour, -arrivals)
  
  return(joined)
}

# -----------------------------------------------------------------------------------
Discrete_Event_Simulation <- function(input_port_rates_df, input_port_of_entry_demand_df) {
  
  # start testing
  # print(paste0("TESTING MODE"))
  # input_port_rates_df <- port_entry_rates_df
  # input_port_of_entry_demand_df <- port_of_entry_demand_df
  # end testing
  
  if (exists("wait_time_df")) remove(wait_time_df)
  if (exists("veh_list_df")) remove(veh_list_df)
  
  DES_SIMULATION_TIME <- 60
  DELIMITER <- "--"
  UNPROCESSED_WAIT_TIME <- 120
  UNPROCESSED_PROCESS_TIME <- 1
  
  market_segments_all <- c("San Ysidro--Northbound--Passenger--General",
                           "San Ysidro--Northbound--Passenger--Ready",
                           "San Ysidro--Northbound--Passenger--SENTRI",
                           "San Ysidro--Southbound--Passenger--_All_",
                           "Otay Mesa--Northbound--Passenger--General",
                           "Otay Mesa--Northbound--Passenger--Ready",
                           "Otay Mesa--Northbound--Passenger--SENTRI",
                           "Otay Mesa--Southbound--Passenger--_All_",
                           "Otay Mesa--Northbound--Commercial--General",
                           "Otay Mesa--Northbound--Commercial--FAST",
                           "Otay Mesa--Southbound--Commercial--_All_",
                           "Otay Mesa East--Northbound--Passenger--General",
                           "Otay Mesa East--Northbound--Passenger--Ready",
                           "Otay Mesa East--Northbound--Passenger--SENTRI",
                           "Otay Mesa East--Southbound--Passenger--_All_",
                           "Otay Mesa East--Northbound--Commercial--General",
                           "Otay Mesa East--Northbound--Commercial--FAST",
                           "Otay Mesa East--Southbound--Commercial--_All_")
  
  # market_segments_vector is different than market_segments_all
  # market_segments_vector is the unique segments that we are running the DES on during the function call
  # market_segments_all is the all possible segments
  # market_segments_vector could be all (for all config DES run) or just few configs (for Allocate_Lanes)
  market_segments_vector <- 
    input_port_rates_df %>%
    mutate(market_segment = paste(port_name, direction, vehicle_type, traveler_type, sep = DELIMITER)) %>%
    .$market_segment
  
  market_segments_vector <- unique(market_segments_vector)

  input_port_rates_df <- input_port_rates_df %>%
    select(hour, port_name, direction, vehicle_type, traveler_type, open_lanes, process_rate, stacked_lanes, stacked_rate)
  
  des_input_df <- input_port_of_entry_demand_df %>%
    group_by(hour, port_name, traveler_type, vehicle_type, direction) %>%
    summarise(veh_arrival = sum(trips, na.rm = T))
  
  des_input_df <- left_join(input_port_rates_df, des_input_df, by = c("hour", "port_name", "direction", "vehicle_type", "traveler_type"))
  des_input_df <- des_input_df %>% replace_na(list(veh_arrival = 0))
  
  remove(input_port_rates_df, input_port_of_entry_demand_df)

  for (market_segment in market_segments_vector) {
    
    #testing
    # market_segment <- market_segments_vector[1]
    # print(paste0(market_segment))
    
    # market segment details
    ms_port_name <- str_split(market_segment, DELIMITER)[[1]][1]
    ms_direction <- str_split(market_segment, DELIMITER)[[1]][2]
    ms_vehicle_type <- str_split(market_segment, DELIMITER)[[1]][3]
    ms_traveler_type <- str_split(market_segment, DELIMITER)[[1]][4]
    
    market_des_df <-
      des_input_df %>%
      filter(port_name == ms_port_name) %>%
      filter(direction == ms_direction) %>%
      filter(vehicle_type == ms_vehicle_type) %>%
      filter(traveler_type == ms_traveler_type)
    
    resource_name <- market_segment
    
    start_hour <- min(market_des_df$hour)
    end_hour <- max(market_des_df$hour)
    
    market_segment_hourly_queue <- NULL
    
    # initialize des outcomes
    previous_hour_queue <- 
      port_configurations_df %>%
      filter(port_name == ms_port_name, direction == ms_direction, vehicle_type == ms_vehicle_type, traveler_type == ms_traveler_type) %>%
      .$initial_queue
    
    previous_hour_wait_time_vector <- rep(0, previous_hour_queue)
    previous_queue_orig_hours_vector <- rep(0, previous_hour_queue)
    
    if (exists("config_results")) remove(config_results)
    
    for (hour_index in seq(start_hour, end_hour)) {
      
      # testing
      #if(hour_index != 19) next;
      # hour_index = 19
      # print(paste0("hour: ", hour_index))
      
      hour_des_df <- 
        market_des_df %>%
        filter(hour == hour_index)
      
      random_seed <- 123456 + hour_index * 100 + which(market_segments_all == market_segment)
      set.seed(random_seed)
      
      open_lanes <- hour_des_df$open_lanes
      stacked_lanes <- hour_des_df$stacked_lanes
      process_rate <- hour_des_df$process_rate
      stacked_rate <- hour_des_df$stacked_rate
      total_arrivals <- ceiling(hour_des_df$veh_arrival)
      
      if (open_lanes > 0 & (total_arrivals + previous_hour_queue) > 0) {
        
        avg_process_rate <- (stacked_rate*stacked_lanes + process_rate*(open_lanes - stacked_lanes))/open_lanes
        
        des_outcome <- des(resource_lanes = open_lanes,
                           process_rate = avg_process_rate,
                           total_arrivals = total_arrivals,
                           existing_queue = previous_hour_queue,
                           simulation_time = DES_SIMULATION_TIME,
                           resource_name = resource_name,
                           seed = random_seed,
                           multi_queue = TRUE)
        
        hour_results_df <- get_arrival_results(des_outcome, 
                                               config = resource_name, 
                                               hour = hour_index, 
                                               prev_queue_orig_hours = previous_queue_orig_hours_vector,
                                               prev_wait_times = previous_hour_wait_time_vector,
                                               ongoing = TRUE) %>%
                           filter(hour>0)  #Chi Ping Lam (8/3/2020) : filter out bogus zero hour records
        
        unprocessed_vehicles_df <- 
          hour_results_df %>%
          filter(is.na(process_time))
        
        processed_vehicles_df <- 
          hour_results_df %>%
          filter(!is.na(process_time))
        
        previous_hour_queue <- nrow(unprocessed_vehicles_df)
        
        if (previous_hour_queue > 0) {
          
          previous_hour_wait_time_vector <- unprocessed_vehicles_df$wait_time
          previous_queue_orig_hours_vector <- unprocessed_vehicles_df$hour
          
        } else {
          
          previous_hour_wait_time_vector <- NULL
          previous_queue_orig_hours_vector <- NULL
          
        }
        
        work_df <- processed_vehicles_df
        if (hour_index == 24) work_df <- hour_results_df
        
        if (exists("config_results")) {
          config_results <- bind_rows(config_results, work_df)
        } else {
          config_results <- work_df
        }
        
        # reset the simulation environment
        reset(des_outcome)
        
      } else {
        previous_hour_queue <- 0
        previous_hour_wait_time_vector <- NULL
        previous_queue_orig_hours_vector <- NULL
      }
      
      market_segment_hourly_queue <- c(market_segment_hourly_queue, previous_hour_queue)
      
    } # hour
  
    # revise the wait time of unprocessed vehicles to a more reasonable value
    if(market_segment_hourly_queue[24] > 0){
    # Chi Ping Lam (7/18/2020)
    #This is the original code causing fatal erro
    #  when using a data frame, first_unprocessed_hour, with the dataframe list, hour  
    #The fix is to turn first_unprocessed_hour to a numeric variable   
      
      first_unprocessed_hour <- config_results[min(which(config_results$processed == FALSE)), "hour"]
    
      first_unprocessed_hour.num <- as.numeric(first_unprocessed_hour)
      config_results <- config_results %>%
        mutate(wait_time = ifelse(processed, wait_time, (24 - first_unprocessed_hour.num)*60 + (hour - first_unprocessed_hour.num + 1)*30))
    }
      
    # aggregate vehicles to calculate median wait for config
    config_wait_df <- config_results %>%
      mutate(wait_time = ifelse(is.na(wait_time), UNPROCESSED_WAIT_TIME, wait_time)) %>%
      mutate(process_time = ifelse(is.na(process_time), UNPROCESSED_PROCESS_TIME, process_time)) %>%
      group_by(hour, config) %>%
      summarise(median_wait_time = median(wait_time), median_process_time = median(process_time)) %>%
      as.data.frame() %>%
      complete(hour=1:24, config) %>%
      replace_na(list(median_wait_time = 0, median_process_time = 0)) %>%
      mutate(queue = market_segment_hourly_queue)
      
    # store vehicle list
    if (exists("veh_list_df")) {
      veh_list_df <- bind_rows(veh_list_df, config_results)
    } else {
      veh_list_df <- config_results
    }
    
    # store wait times
    if (exists("wait_time_df")) {
      wait_time_df <- bind_rows(wait_time_df, config_wait_df)
    } else {
      wait_time_df <- config_wait_df
    }
    
  } # market
  
  results <- list()
  results$wait_times <- wait_time_df
  results$des_details <- veh_list_df
  
  return(results) 
}

#' Main DES Model Function
#'
#' This function takes different simulation attributes and runs discrete event simulation (des).
#' 
#' @param resource_lanes Number of resource lanes (inspection booth in this case)
#' @param process_rate Average processing rate at the server in the simulation environment
#' @param total_arrivals Total number of arrivals in the simulation environment
#' @param existing_queue Queue from previous hour to this hour
#' @param simulation_time Simulation time to the des model
#' @param resource_name Name of the resource for the simulation
#' @param multi_queue If the vehicles at the server (inspection point) are making a single queue or multiple queue
#'   FALSE is single queue, True is multiple queue
#'   
#' @return The simulation enviroment
#'
#' @examples
#' des(1, 60, 500, 0, 60, "SY_POV_GP", 123, TRUE)
#' des(4, 75, 800, 100, 60, "OM_POV_GP", 5674, TRUE)
#'
#' @export
des <- function(resource_lanes, process_rate, total_arrivals, existing_queue, simulation_time, resource_name, seed, multi_queue = TRUE) {
  # initialize a simulation environment
  env <- simmer()
  
  # creates required random processing times with mean as process rate
  processing_times <- getRandomProcessingTimes(vehicles = total_arrivals + existing_queue, meanVal = simulation_time/process_rate, seed = seed)
  
  # initialize and create a trajectory object
  if(multi_queue){
    resources <- paste(resource_name, 1:resource_lanes, sep="_")
    vehicle <- get_trajectory_multiQ(resources, processing_times)
  } else {
    vehicle <- get_trajectory_singleQ(resource_name, processing_times)
  }
  
  # define and create new resource(s)
  if(multi_queue){
    env <- get_multiQ_resources(env, resources)
  } else {
    env <- get_singleQ_resources(env, resource_name, resource_lanes)
  }
  
  # add new generator of arrival for previous hour queue with arrival time of zero for this hour
  if(existing_queue > 0){
    env <- env %>% add_generator(name_prefix = "prev", trajectory = vehicle, distribution = at(c(rep(0,existing_queue))))
  }
  
  # add new generator of arrival for vehicles arriving in thie hour
  if(total_arrivals > 0){
    # this is an additional step to generate random arrival time for vehicles but 
    # also making sure that the EXACT numbers of vehicles are generated during
    # the simulated time.
    # without this additional step, rexp generates random arrival time but total generated vehices 
    # won't match to the arriving vehicles.
    
    # generate n arrival times with average as simulation_time/total_arrivals
    # example generate arrival time for 120 vehicles with average arrival time as 0.5 (60/120)
    set.seed(seed)
    arrival_times <- rexp(total_arrivals, total_arrivals/simulation_time)
    
    # if sum of arrival time for the above generated random arrivals is more than simulation_time
    # arrival times (random numbers) are factored such that the sum will become equal to simulation_time
    # thus making sure that the exact n vehicles are generated during the simulation time. 
    # arrival_times_final are the final random arrival times. 
    
    if(sum(arrival_times) <= simulation_time) {
      arrival_times_final <- arrival_times 
    } else {
      factor <- (sum(arrival_times) - simulation_time)/(total_arrivals)
      factor_final <- factor * total_arrivals / length(arrival_times[arrival_times >= factor])
      arrival_times_final <- sapply(arrival_times, function(x) max(x - factor_final, 0))
    }
    
    # add generator for these vehicles arriving during the simulation hour 
    env <- env %>% add_generator(name_prefix = "veh", trajectory = vehicle, distribution = function() {c(arrival_times_final, -1)})
  }
  
  # run (execute) the simulation until the given time
  env %>% run(until=simulation_time)

  # return the simulated environment
  return(env)
}

getRandomProcessingTimes <- function(vehicles, meanVal, seed){
  minVal <- 0.5 * meanVal
  maxVal <- 3.0 * meanVal
  
  converged <- 0
  criteria <- 0.01
  
  rate <- 1/meanVal
  
  # TODO - document what is done here!
  while (converged == 0) {
    set.seed(seed)
    x <- rexp(vehicles, rate)
    y <- ifelse(x < minVal, minVal, ifelse(x > maxVal, maxVal, x))
    
    if(abs(mean(y) - meanVal) < criteria) converged = 1
    
    rate <- rate * mean(y)/meanVal
  }
  
  return(y)
}

#' Create trajectory for single queue
#' 
#' @param resource Name of the resource.
#' @param processing_times Randomly generated processing times. 
#' 
#' @return The vehicle trajectory
#'
#' @export
get_trajectory_singleQ <- function(resource, processing_times){
  vehicle <- trajectory() %>%
    seize(resource, amount=1) %>%
    timeout(function(){sample(processing_times, 1)}) %>%
    release(resource, amount=1)
  
  return(vehicle)
}

#' Create trajectory for multiple queue
#' 
#' New vehicles arriving into the enviroment joins the shortest queue
#' 
#' @param resources List of resource names
#' @param processing_times Randomly generated processing times. 
#' 
#' @return The vehicle trajectory
#'
#' @export
get_trajectory_multiQ <- function(resources, processing_times){
  vehicle <- trajectory() %>%
    simmer::select(resources, policy = "shortest-queue") %>%
    seize_selected %>%
    timeout(function(){sample(processing_times, 1)}) %>%
    release_selected
  
  return(vehicle)
}

#' Define new resource for single queue
#' 
#' @param env Simulation Environment.
#' @param resource_name Name of the resource.
#' @param resource_lanes Number of server lanes. Capacity is number of lanes for single queue.
#' 
#' @return The simulated enviroment with resource added
#'
#' @export
get_singleQ_resources <- function(env, resource_name, resource_lanes){
  env <- env %>% add_resource(name = resource_name, capacity = resource_lanes)
  return(env)
}

#' Define new resources for multiple queue
#' 
#' @param env Simulation Environment.
#' @param resources List of the resource names. Capacity is 1 per resource for multi queue.
#' 
#' @return The simulated enviroment with resource added
#'
#' @export
get_multiQ_resources <- function(env, resources){
  num_resources <- length(resources)
  for(n in 1:num_resources){
    env <- env %>% add_resource(name = resources[n], capacity = 1)
  }
  return(env)
}

#' Function for getting the simulation data from the enviroment
#' 
#' @param des_env Simulation Environment.
#' @param type Type of the resource. E.g., "SY_POV_GP"
#' @param ongoing If TRUE, ongoing arrivals will be reported, vehicles that have arrived but are not processed yet.
#' @param prev_wait_times Wait time vector for the vehicles in queue from previous hour.
#'   Used to calculate the true wait time for the vehicles.
#'   
#' @return Returns a data frame with simulation results.
#'
#' @export
get_arrival_results <- function(des_env, config, hour, prev_queue_orig_hours, prev_wait_times, ongoing){
  # default getter for obtaining monitored arrival data
  results <- des_env %>% get_mon_arrivals(ongoing=ongoing) %>% dplyr::filter(start_time != -1)
  
  # sort the data by start time attribute
  results <- results[order(results$start_time),]
  
  # attached info about vehicle getting processed in which hour
  setDT(results)[finished == TRUE, processed_hour := hour]
  
  # if prev_queue_orig_hours is null, create zero column for prev wait times 
  if(is.null(prev_queue_orig_hours)){
    total_veh = nrow(results)
    results <- results %>% dplyr::mutate(prev_wait_time = rep(0,total_veh))
    results <- results %>% dplyr::mutate(hour = c(rep(hour,total_veh)))
  }
  
  # if prev_queue_orig_hours is not null, create the prev wait times column accordingly. 
  # prev_wait_times for vehicles in queue from previous hour, 0 for new vehicles arriving in this hour.
  if(!is.null(prev_queue_orig_hours)){
    total_veh <- nrow(results)
    prev_veh <- length(prev_queue_orig_hours)
    new_veh <- total_veh - prev_veh
    results <- results %>% dplyr::mutate(prev_wait_time = c(prev_wait_times,rep(0,new_veh)))
    results <- results %>% dplyr::mutate(hour = c(prev_queue_orig_hours,rep(hour,new_veh)))
  }
  
  # calculate appropriate wait time value
  setDT(results)[finished == TRUE, wait_time := prev_wait_time + (end_time - activity_time - start_time)]
  setDT(results)[finished == FALSE, wait_time := prev_wait_time + (60 - start_time)]
  
  # format data
  results <- results %>% dplyr::select(hour, start_time, wait_time, activity_time, end_time, finished, processed_hour)
  names(results) <- c("hour", "arrival_time", "wait_time", "process_time", "exit_time", "processed", "processed_hour")
  
  results$arrival_time <- round(results$arrival_time, 4)
  results$wait_time <- round(results$wait_time, 4)
  results$process_time <- round(results$process_time, 4)
  results$exit_time <- round(results$exit_time, 4)
  
  # add config information to the results
  results <- results %>% dplyr::mutate(config = config)
  
  results <- results %>% dplyr::select(hour, config, arrival_time, wait_time, process_time, exit_time, processed, processed_hour)
  
  return(results)
}
