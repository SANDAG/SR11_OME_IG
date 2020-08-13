# Allocate Demand to Ports of Entry
#
# Wrapper to call the port of entry choice and the DES iteratively

rm(list = ls(all.names=TRUE))

# -----------------------------------------------------------------------------------
# Command line
args <- commandArgs(trailingOnly = TRUE)
properties_file <- args[1]
START_ITER <- as.numeric(args[2])
END_ITER <- as.numeric(args[3])

# testing
#properties_file <- "C:/Projects/sr11_ome_v21/config/sr11_ome.properties"
#START_ITER <- 11
#END_ITER <- 20

print("Initialization ... ")

# -----------------------------------------------------------------------------------
# R Packages
packages_vector <- c("simmer", "tidyverse", "data.table", "properties", "openxlsx")

need_to_install <- packages_vector[!(packages_vector %in% installed.packages()[,"Package"])]

if (length(need_to_install)) install.packages(need_to_install)

for (package in packages_vector){
  suppressWarnings(suppressMessages(library(package, character.only = TRUE)))
}

if (packageVersion("tidyverse") < 1.2) install.packages("tidyverse")

# -----------------------------------------------------------------------------------
# Remote I/O
properties <- read.properties(properties_file)

model_dir <- trimws(properties$`model.dir `)
setwd(model_dir)
data_in_dir <- paste0(model_dir, "data_in/")
data_out_dir <- paste0(model_dir, "data_out/")

source_dir <- paste0(trimws(properties$`source.dir `)) 
trips_dir <- paste0(trimws(properties$`trips.dir `)) 
skims_dir <- paste0(trimws(properties$`skims.dir `)) 
assignment_dir <- paste0(trimws(properties$`assignment.dir `))

port_configurations_file <- paste0(model_dir, trimws(properties$`port.configuration.input.file.name `))
port_of_entry_rates_file <- paste0(model_dir, trimws(properties$`poe.rate.file.name`))
value_of_time_file <- paste0(model_dir, trimws(properties$`value.of.time.file.name`))
output_for_assignment_file <- paste0(model_dir, trimws(properties$`output.for.assignment.file.name `))
legacy_output_file <- paste0(model_dir, trimws(properties$`output.legacy.file.name `))
des_details_output_file <- paste0(model_dir, trimws(properties$`output.des.details.file.name `))
observed_data_file <- paste0(model_dir, trimws(properties$`optional.observed.data.for.calibration.file.name `))

MAXIMUM_US_ZONE_NUMBER <- as.numeric(properties$`maximum.us.zone.number `)
OTAY_MESA_EAST <- as.logical(as.numeric(properties$`do.ome `))

SAVE_RESULTS_BY_ITER <- as.logical(trimws(properties$`save.results.by.iter `))
TRACE <- as.logical(trimws(properties$`trace `))
WARM_START <- as.logical(trimws(properties$`warm.start `))
CALIBRATION <- as.logical(trimws(properties$`calibration.mode `))

warm_start_output_location <- paste0(trimws(properties$`warm.start.output.location `)) 
config_file <- paste0(trimws(properties$`run.config.file `)) 

if(TRACE) {
  trace_otaz <- as.numeric(trimws(properties$`trace.otaz `))
  trace_dtaz <- as.numeric(trimws(properties$`trace.dtaz `))
  trace_hour <- as.numeric(trimws(properties$`trace.hour `))
  trace_vehicle_type <- trimws(properties$`trace.vehicle.type `)
  trace_direction <- trimws(properties$`trace.direction `)
  trace_traveler_type <- trimws(properties$`trace.traveler.type `)
}

trip_file_vector <- sprintf(paste0(model_dir, trips_dir, "Trips_%d.RDS"), 1:24)
skim_file_vector <- sprintf(paste0(model_dir, skims_dir, "Skims_%d.RDS"), 1:24)

# -----------------------------------------------------------------------------------
# Parameters
desired_non_zero_trip_table_vector <- c("HBO_General", "HBO_Ready", "HBO_SENTRI", 
                                        "HBW_General", "HBW_Ready", "HBW_SENTRI", 
                                        "HBS_General", "HBS_Ready", "HBS_SENTRI",
                                        "Loaded_GP", "Loaded_FAST", "Empty_GP", "Empty_FAST") 

DELIMITER <- "--"
OTAY_MESA_EAST_NAME <- "Otay Mesa East"

# -----------------------------------------------------------------------------------
# R Helper Methods
source(paste0(source_dir,"discrete_event_simulation.R"))
source(paste0(source_dir,"port_of_entry_choice.R"))

# -----------------------------------------------------------------------------------
# Read Configuration files, port of entry rates, value of time 
port_configurations_df <- read.csv(port_configurations_file, stringsAsFactors = FALSE)
port_entry_rates_df <- Reformat_Port_of_Entry_Rates(port_of_entry_rates_file, port_configurations_df)

value_of_time_df <- read.csv(value_of_time_file, stringsAsFactors = FALSE, colClasses = 'character')
value_of_time_df <- value_of_time_df %>% mutate(value_of_time_dollars = as.numeric(value_of_time_dollars))

# Remove Otay Mesa East if requested
if (!OTAY_MESA_EAST) {
  port_configurations_df <- 
    port_configurations_df %>%
    filter(port_name != OTAY_MESA_EAST_NAME)
  
  port_entry_rates_df <- 
    port_entry_rates_df %>%
    filter(port_name != OTAY_MESA_EAST_NAME)
}

# Get default toll values
if (OTAY_MESA_EAST) {
  ome_toll_df <- 
    port_configurations_df %>%
    filter(port_name == OTAY_MESA_EAST_NAME) %>%
    group_by(vehicle_type, direction) %>%
    summarise(toll_in_cents = mean(default_toll_in_dollars) * 100)
  
  nb_pov_min_toll <- ome_toll_df %>% filter(vehicle_type == "Passenger", direction == "Northbound") %>% .$toll_in_cents
  sb_pov_min_toll <- ome_toll_df %>% filter(vehicle_type == "Passenger", direction == "Southbound") %>% .$toll_in_cents
  
  nb_com_min_toll <- ome_toll_df %>% filter(vehicle_type == "Commercial", direction == "Northbound") %>% .$toll_in_cents
  sb_com_min_toll <- ome_toll_df %>% filter(vehicle_type == "Commercial", direction == "Southbound") %>% .$toll_in_cents
  
  min_toll_vector <- c(nb_pov_min_toll, sb_pov_min_toll, nb_com_min_toll, sb_com_min_toll)
  names(min_toll_vector) <- c("PV_NB_MIN_TOLL", "PV_SB_MIN_TOLL", "CV_NB_MIN_TOLL", "CV_SB_MIN_TOLL")
} else {
  min_toll_vector <- c(0, 0, 0, 0)
  names(min_toll_vector) <- c("PV_NB_MIN_TOLL", "PV_SB_MIN_TOLL", "CV_NB_MIN_TOLL", "CV_SB_MIN_TOLL")
}

# -----------------------------------------------------------------------------------
# Convert TransCAD CSV to RDS (if needed)

## trip tables
for (hour_of_day in 1:24){
  
  tc_csv_mtx_file <- sprintf(paste0(model_dir, trips_dir, "Trips_%d.CSV"), hour_of_day)
  tc_dcc_mtx_file <- sprintf(paste0(model_dir, trips_dir, "Trips_%d.DCC"), hour_of_day)
  r_df_file <- sprintf(paste0(model_dir, trips_dir, "Trips_%d.RDS"), hour_of_day)
  
  if (!file.exists(r_df_file)) {
    if(hour_of_day == 1) print("Converting Trip Tables from CSV to RDS ... ")
    TransCAD_Trip_CSV_Matrix_to_R(tc_csv_mtx_file, tc_dcc_mtx_file, r_df_file, desired_non_zero_trip_table_vector) 
  } 
  
}

## skims
for (hour_of_day in 1:24){
  
  tc_csv_mtx_file <- sprintf(paste0(model_dir, skims_dir, "Skims_%d.CSV"), hour_of_day)
  tc_dcc_mtx_file <- sprintf(paste0(model_dir, skims_dir, "Skims_%d.DCC"), hour_of_day)
  r_df_file <- sprintf(paste0(model_dir, skims_dir, "Skims_%d.RDS"), hour_of_day)
  
  if (!file.exists(r_df_file)) {
    if(hour_of_day == 1) print("Converting Skims from CSV to RDS ... ")
    TransCAD_Skim_CSV_Matrix_to_R(tc_csv_mtx_file, tc_dcc_mtx_file, r_df_file, unique(port_configurations_df$port_zone)) 
  }
  
}

# -----------------------------------------------------------------------------------
# Load trimmed trips and trimmed skims into memory (small data, so do every time for now)
trips_df_list <- Read_Trips_And_Skims(trip_file_vector)
skims_df_list <- Read_Trips_And_Skims(skim_file_vector)

# -----------------------------------------------------------------------------------
# Label trips with direction
for(hour_index in 1:24) {
  
  work_df <- 
    trips_df_list[[hour_index]] %>%
    mutate(direction = "Northbound") %>%
    mutate(direction = ifelse(orig <= MAXIMUM_US_ZONE_NUMBER & dest > MAXIMUM_US_ZONE_NUMBER, 
                              "Southbound", direction))
  
  trips_df_list[[hour_index]] <- work_df
  
  
}
remove(work_df)

# Read config file
config_file <- paste0(model_dir, config_file)
if(file.exists(config_file)) {
  config_df <- read.csv(config_file)
  MAX_ITERATIONS <- max(config_df$iter)
} else {
  MAX_ITERATIONS <- 100
}

SAVE_END_ITER_RESULTS <- TRUE

if(is.na(START_ITER)) START_ITER <- 1
if(is.na(END_ITER)) {
  END_ITER <- MAX_ITERATIONS
  SAVE_END_ITER_RESULTS <- FALSE
}

# create debug directory, if needed
if(SAVE_RESULTS_BY_ITER){
  debug_dir <- paste0(data_out_dir, "debug/")
  if(!dir.exists(debug_dir)) { dir.create(debug_dir) }
}

# -----------------------------------------------------------------------------------
if(WARM_START) {
  port_of_entry_demand_file <- paste0(warm_start_output_location, "port_of_entry_demand_df.csv")
  des_outcomes_file <- paste0(warm_start_output_location, "des_outcomes_df.csv")
  port_entry_rates_file <- paste0(warm_start_output_location, "port_entry_rates_df.csv")
  
  if(file.exists(port_of_entry_demand_file)) {
    port_of_entry_demand_df <- read.csv(port_of_entry_demand_file, stringsAsFactors = FALSE)
    
    port_of_entry_demand_df <- left_join(port_of_entry_demand_df, port_configurations_df, by = c("port_name", "port_zone", "vehicle_type", "traveler_type", "direction")) %>%
      mutate(bias_constant = port_choice_bias_constant) %>%
      select(-c(trip_table_suffix, default_toll_in_dollars, port_choice_bias_constant))
  } else {
    stop("warm start file 'port_of_entry_demand_df.csv' does not exists!!!")
  }
  
  if(file.exists(des_outcomes_file)) {
    des_outcomes_df <- read.csv(des_outcomes_file, stringsAsFactors = FALSE)
  } else {
    stop("warm start file 'des_outcomes_df.csv' does not exists!!!")
  }
  
  if(file.exists(port_entry_rates_file)) port_entry_rates_df <- read.csv(port_entry_rates_file, stringsAsFactors = FALSE)
  
  # drop OME if present in warm start files and scenario is not running OME
  if (!OTAY_MESA_EAST) {
    port_of_entry_demand_df <- port_of_entry_demand_df %>% filter(port_name != OTAY_MESA_EAST_NAME)
    port_entry_rates_df <- port_entry_rates_df %>% filter(port_name != OTAY_MESA_EAST_NAME)
    des_outcomes_df <- des_outcomes_df %>% filter(!grepl(OTAY_MESA_EAST_NAME, config))
  }
  
} else {
  if(START_ITER == 1){
    # Solve Initial Port Allocation (based on zero port times)
    port_of_entry_demand_df <- Port_of_Entry_Choice_Initial(trips_df_list, skims_df_list, port_configurations_df, port_entry_rates_df, value_of_time_df)
    
    # Port times based on initial port allocation demand
    des_outcomes_df <- (Discrete_Event_Simulation(port_entry_rates_df, port_of_entry_demand_df))$wait_times
    
    prior_des_outcomes_df <- des_outcomes_df %>%
      mutate(median_wait_time = 0, median_process_time = 0, queue = 0)
    
    # weighted average of the zero and initial port of entry wait times
    # Chi Ping Lam 7/23/2020
    # For the first iteration, the des_outcomes_df should be simply the rsesult of first simulation
    #   and there is need to compute a weighted average (no previous result!)
    # There is no base of apply a 0.9 factor here too 
    #des_outcomes_df <- Compute_Weighted_Average_Wait_Time(des_outcomes_df, prior_des_outcomes_df, 0.9)
    
  } else {
    debug_dir <- paste0(data_out_dir, "debug/")
    des_outcomes_df <- read.csv(paste0(debug_dir, "des_outcomes_df_", START_ITER - 1, ".csv"), stringsAsFactors = FALSE)
    port_of_entry_demand_df <- read.csv(paste0(debug_dir, "port_of_entry_demand_df_", START_ITER - 1, ".csv"), stringsAsFactors = FALSE)
    port_entry_rates_df <- read.csv(paste0(debug_dir, "port_entry_rates_df_", START_ITER - 1, ".csv"), stringsAsFactors = FALSE)
    
  }
  
}

# release the trips and skims from memory
remove(trips_df_list)
remove(skims_df_list)

iterations <- START_ITER
WEIGHT = 0.99
ALLOCATE_LANES = FALSE
OPTIMIZE_TOLL = FALSE

while (iterations <= END_ITER) {
  print(paste0("Solving Demand Allocation Iteration ",iterations,"."))
  
  if(exists("config_df")) {
    iter_config <- config_df %>% filter(iter == iterations)
    WEIGHT         <- iter_config$weight
    ALLOCATE_LANES <- as.logical(iter_config$do_lane)
    OPTIMIZE_TOLL  <- as.logical(iter_config$do_toll)
  }
  
  port_of_entry_demand_df <- Update_Port_Times(port_of_entry_demand_df, des_outcomes_df)
  
  port_of_entry_demand_df <- Port_of_Entry_Choice_Update(port_of_entry_demand_df, value_of_time_df)
  
  pre_des_outcomes_df <- (Discrete_Event_Simulation(port_entry_rates_df, port_of_entry_demand_df))$wait_times
  
  port_of_entry_demand_df <- Add_Des_Times(port_of_entry_demand_df, pre_des_outcomes_df, "des_pre_lane")
  
  if (ALLOCATE_LANES) {
    port_entry_rates_df <- Update_Lane_Configuration(port_entry_rates_df, port_of_entry_demand_df, min_toll_vector)
    
    # update open lanes in the demand df
    port_of_entry_demand_df <- left_join(port_of_entry_demand_df, 
                                         port_entry_rates_df %>% select(hour, port_name, direction, vehicle_type, traveler_type, new_open_lanes = open_lanes),
                                         by = c("hour", "port_name", "direction", "vehicle_type", "traveler_type")) %>%
      mutate(open_lanes = new_open_lanes) %>% 
      select(-new_open_lanes)
    
  }
  
  if (OPTIMIZE_TOLL) {
    port_of_entry_demand_df <- Update_Port_Toll_Costs(port_of_entry_demand_df, port_entry_rates_df, min_toll_vector)
  }
  
  prior_des_outcomes_df <- des_outcomes_df
  
  des_results <- Discrete_Event_Simulation(port_entry_rates_df, port_of_entry_demand_df)
  
  des_outcomes_df <- des_results$wait_times
  detailed_des_outcomes_df <- des_results$des_details
  
  port_of_entry_demand_df <- Add_Des_Times(port_of_entry_demand_df, des_outcomes_df, "des_post_lane")
  
  des_outcomes_df <- Compute_Weighted_Average_Wait_Time(des_outcomes_df, prior_des_outcomes_df, WEIGHT)
  
  # save iteration result
  if(SAVE_RESULTS_BY_ITER | (SAVE_END_ITER_RESULTS & iterations == END_ITER)){
    debug_dir <- paste0(data_out_dir, "debug/")
    if(!dir.exists(debug_dir)) { dir.create(debug_dir) }
    write.csv(port_of_entry_demand_df, paste0(debug_dir, "port_of_entry_demand_df_", iterations, ".csv"), row.names = FALSE)
    write.csv(port_entry_rates_df, paste0(debug_dir, "port_entry_rates_df_", iterations, ".csv"), row.names = FALSE)    
    write.csv(des_outcomes_df, paste0(debug_dir, "des_outcomes_df_", iterations, ".csv"), row.names = FALSE)    
  }
  
  # add trace log
  if(TRACE){
    log_file <- paste0(data_out_dir, "trace_log.txt")
    
    if(iterations == 1 & file.exists(log_file))
      file.remove(log_file)
    
    trace_log <- Create_Trace_Log(port_of_entry_demand_df, iterations, trace_otaz, trace_dtaz, trace_hour, trace_vehicle_type, trace_direction, trace_traveler_type)
    
    if(!is.null(trace_log)){
      conn <- file(log_file, "a")
      writeLines(trace_log, conn)
      close(conn)
    }
  }
  
  iterations <- iterations + 1
  
  gc()
}

if(END_ITER == MAX_ITERATIONS){
  # -----------------------------------------------------------------------------------
  # Write Assignment Ready Data to Disk
  write_df <- 
    port_of_entry_demand_df %>%
    #select(hour, orig, dest, direction, port_name, vehicle_type, traveler_type, trips) %>%
    arrange(port_name, direction, hour, orig, dest, vehicle_type, traveler_type)
  
  write.csv(write_df, file = output_for_assignment_file, row.names = FALSE)
  
  
  # -----------------------------------------------------------------------------------
  # Write Detailed Vehicle List from DES
  detailed_des_outcomes_df <- 
    detailed_des_outcomes_df %>%
    separate(config, into = c("port_name", "direction", "vehicle_type", "traveler_type"), sep = DELIMITER, remove = TRUE)
  write.csv(detailed_des_outcomes_df, file = des_details_output_file, row.names = FALSE)
  
  # -----------------------------------------------------------------------------------
  # Write Legacy Output to Disk
  POE <- c("SY", "OM", "OME")
  port_name <- c("San Ysidro", "Otay Mesa", "Otay Mesa East")
  legacy_name_df <- data.frame(POE, port_name, stringsAsFactors = FALSE)
  remove(POE, port_name)
  
  Lane <- c("POV_GP", "POV_RE", "POV_SE", "POV_SB", "COM_GP", "COM_SP", "COM_SB")
  direction <- c("Northbound", "Northbound", "Northbound", "Southbound", "Northbound", "Northbound", "Southbound")
  vehicle_type <- c("Passenger", "Passenger", "Passenger", "Passenger", "Commercial", "Commercial", "Commercial")
  traveler_type <- c("General", "Ready", "SENTRI", "_All_", "General", "FAST", "_All_")
  legacy_lane_df <- data.frame(Lane, direction, vehicle_type, traveler_type, stringsAsFactors = FALSE)
  remove(Lane, direction, vehicle_type, traveler_type)
  
  join_legacy <- 
    port_of_entry_demand_df %>%
    group_by(hour, port_name, direction, vehicle_type, traveler_type) %>%
    summarise(volume = sum(trips), port_toll_cost = mean(port_toll_cost))
  
  join_des_outcomes <- 
    des_outcomes_df %>%
    separate(config, into = c("port_name", "direction", "vehicle_type", "traveler_type"), sep = DELIMITER, remove = TRUE)
  
  join_port_rates_inputs <- 
    port_entry_rates_df %>%
    select(hour, port_name, direction, vehicle_type, traveler_type, open_lanes, stacked_lanes)
  
  joined <- left_join(join_des_outcomes, join_legacy, by = c("hour", "port_name", "direction", "vehicle_type", "traveler_type"))
  joined <- left_join(joined, join_port_rates_inputs, by = c("hour", "port_name", "direction", "vehicle_type", "traveler_type"))
  joined[is.na(joined)] <- 0
  
  # add hourly processed rate
  joined <- as.data.frame(joined)
  joined <- joined %>%
    arrange(port_name,direction,vehicle_type,traveler_type,hour) %>%
    mutate(processed_volume = 0)
  
  #Chi Ping Lam (8/3/2020)
  #The codes below requires each config must have exactly 24 records, one for each hour
  # otherwise the volume calculation is just wrong
  #preload_df <- port_configurations_df %>%
  #    unite("config", c("port_name", "direction", "vehicle_type", "traveler_type"), sep = DELIMITER) %>%
  #    select(config, initial_queue)
  #
  #for (i in 1:(length(unique(des_outcomes_df$config)))){
  #  preload <- preload_df %>% filter(config == unique(des_outcomes_df$config)[i]) %>% .$initial_queue
  #  for(j in 1:24){
  #    joined$processed_volume[(i-1)*24+j] <- ifelse(j==1,(joined$volume-joined$queue)[(i-1)*24+j] + preload,(joined$volume-joined$queue)[(i-1)*24+j]+joined$queue[(i-1)*24+j-1])
  #  }
  #}
  #
  #Here is the revised script using join rahter than for loop
  preload_df <- port_configurations_df %>%
     select(port_name, direction, vehicle_type, traveler_type, initial_queue)
  joined_prev_hr <- joined %>% select (hour, port_name, direction, vehicle_type, traveler_type, queue) %>%
      mutate(hour = hour + 1) %>%
      rename(prev_queue = queue) 
  joined <- left_join(joined, joined_prev_hr, by=c("hour", "port_name", "direction", "vehicle_type", "traveler_type")) %>%   
     mutate(prev_queue = replace_na(prev_queue,0)) %>%
     left_join(preload_df, by=c("port_name", "direction", "vehicle_type", "traveler_type")) %>%
     mutate(processed_volume = ifelse(hour==1,volume-queue+initial_queue, volume-queue+prev_queue)) %>%
     select(-prev_queue)
  rm(joined_prev_hr)  
  
  # use this later
  simulated_outcomes_df <- joined
  
  joined <- left_join(joined, legacy_name_df, by = c("port_name"))
  joined <- left_join(joined, legacy_lane_df, by = c("direction", "vehicle_type", "traveler_type"))
  
  legacy_write_df <- 
    joined %>%
    mutate(NB_POV_Toll = ifelse(direction == "Northbound" & vehicle_type == "Passenger", port_toll_cost/100, 0.0)) %>%
    mutate(NB_TRK_Toll = ifelse(direction == "Northbound" & vehicle_type == "Commercial", port_toll_cost/100, 0.0)) %>%
    mutate(SB_POV_Toll = ifelse(direction == "Southbound" & vehicle_type == "Passenger", port_toll_cost/100, 0.0)) %>%
    mutate(SB_TRK_Toll = ifelse(direction == "Southbound" & vehicle_type == "Commercial", port_toll_cost/100, 0.0)) %>%
    select(Hour = hour, POE, Lane, Open = open_lanes, Stacked = stacked_lanes, Volume = volume, Wait_Time = median_wait_time, Queue = queue, Processed_Volume = processed_volume,
           NB_POV_Toll, NB_TRK_Toll, SB_POV_Toll, SB_TRK_Toll) %>%
    arrange(Lane, POE, Hour)
  
  write.csv(legacy_write_df, file = legacy_output_file, row.names = FALSE)
  
  remove(joined, join_port_rates_inputs, join_des_outcomes, join_legacy, legacy_lane_df, legacy_name_df)
  
  # -----------------------------------------------------------------------------------
  # Write output in another excel format
  
  if("OME" %in% unique(legacy_write_df$POE)) {
    lane_type <- c("POV_GP_SY","POV_RE_SY","POV_SE_SY","POV_SB_SY",
                   "POV_GP_OM","POV_RE_OM","POV_SE_OM","POV_SB_OM","COM_GP_OM","COM_SP_OM","COM_SB_OM",
                   "POV_GP_OME","POV_RE_OME","POV_SE_OME","POV_SB_OME","COM_GP_OME","COM_SP_OME","COM_SB_OME")
  } else {
    lane_type <- c("POV_GP_SY","POV_RE_SY","POV_SE_SY","POV_SB_SY",
                   "POV_GP_OM","POV_RE_OM","POV_SE_OM","POV_SB_OM","COM_GP_OM","COM_SP_OM","COM_SB_OM")
  }
  
  legacy_write_df <- legacy_write_df %>% mutate(Type = factor(paste(Lane, POE, sep = "_"), levels = lane_type))
  
  results_file <- paste(data_out_dir, paste0("results.xlsx"), sep = "/")
  if(file.exists(results_file)) file.remove(results_file)
  
  # open lanes
  open_lanes <- legacy_write_df %>% select(Hour, Type, Open)
  open_lanes[is.na(open_lanes)] <- 0
  open_lanes <- open_lanes %>% spread(key = Type, value = Open)
  addWorksheet(results_wb, "open_lanes")
  writeData(results_wb, "open_lanes", open_lanes,startCol=1, startRow=1, colNames=TRUE, rowNames=FALSE)
  
  # period vol
  period_vol <- legacy_write_df %>% select(Hour, Type, Volume)
  period_vol[is.na(period_vol)] <- 0 
  period_vol <- period_vol %>% mutate(Volume = as.integer(Volume))
  period_vol <- period_vol %>% spread(key = Type, value = Volume)
  addWorksheet(results_wb, "period_volume")
  writeData(results_wb, "period_volume", period_vol, startCol=1, startRow=1, colNames=TRUE, rowNames=FALSE)
  
  # wait time
  wait_time <- legacy_write_df %>% select(Hour, Type, Wait_Time)
  wait_time[is.na(wait_time)] <- 0 
  wait_time <- wait_time %>% spread(key = Type, value = Wait_Time)
  addWorksheet(results_wb, "wait_time")
  writeData(results_wb, "wait_time", wait_time,startCol=1, startRow=1, colNames=TRUE, rowNames=FALSE)
  
  # queue
  queue <- legacy_write_df %>% select(Hour, Type, Queue)
  queue[is.na(queue)] <- 0 
  queue <- queue %>% spread(key = Type, value = Queue)
  addWorksheet(results_wb, "queue")
  writeData(results_wb, "queue", queue, startCol=1, startRow=1, colNames=TRUE, rowNames=FALSE)
  
  if("OME" %in% unique(legacy_write_df$POE)) {
    #toll
    nb_pov_toll <- legacy_write_df %>% filter(POE == "OME", Lane == "POV_GP") %>% .$NB_POV_Toll
    sb_pov_toll <- legacy_write_df %>% filter(POE == "OME", Lane == "POV_SB") %>% .$SB_POV_Toll
    nb_com_toll <- legacy_write_df %>% filter(POE == "OME", Lane == "COM_GP") %>% .$NB_TRK_Toll
    sb_com_toll <- legacy_write_df %>% filter(POE == "OME", Lane == "COM_SB") %>% .$SB_TRK_Toll
    
    toll <- data.frame(Hour = 1:24, NB_POV = nb_pov_toll, SB_POV = sb_pov_toll, NB_COV = nb_com_toll, SB_COV = sb_com_toll)
    addWorksheet(results_wb, "tolls")
    writeData(results_wb, "tolls", toll ,startCol=1, startRow=1, colNames=TRUE, rowNames=FALSE)
  }
  
  # -----------------------------------------------------------------------------------
  # write out trips by port/lane_type/hour in csv format to be then converted to TransCAD matrices
  trips_df <- port_of_entry_demand_df %>%
    mutate(core = case_when(
      vehicle_type == "Passenger" & (traveler_type == "General" | traveler_type == "_All_") & port_name == "San Ysidro" ~ "POV_GP_SY",
      vehicle_type == "Passenger" & traveler_type == "Ready" & port_name == "San Ysidro" ~ "POV_RE_SY",
      vehicle_type == "Passenger" & traveler_type == "SENTRI" & port_name == "San Ysidro" ~ "POV_SE_SY",
      vehicle_type == "Passenger" & (traveler_type == "General" | traveler_type == "_All_") & port_name == "Otay Mesa" ~ "POV_GP_OM",
      vehicle_type == "Passenger" & traveler_type == "Ready" & port_name == "Otay Mesa" ~ "POV_RE_OM",
      vehicle_type == "Passenger" & traveler_type == "SENTRI" & port_name == "Otay Mesa" ~ "POV_SE_OM",
      vehicle_type == "Passenger" & (traveler_type == "General" | traveler_type == "_All_") & port_name == "Otay Mesa East" ~ "POV_GP_OME",
      vehicle_type == "Passenger" & traveler_type == "Ready" & port_name == "Otay Mesa East" ~ "POV_RE_OME",
      vehicle_type == "Passenger" & traveler_type == "SENTRI" & port_name == "Otay Mesa East" ~ "POV_SE_OME",
      vehicle_type == "Commercial" & (traveler_type == "General" | traveler_type == "_All_") & port_name == "Otay Mesa" ~ "COM_GP_OM",
      vehicle_type == "Commercial" & traveler_type == "FAST" & port_name == "Otay Mesa" ~ "COM_SP_OM",
      vehicle_type == "Commercial" & (traveler_type == "General" | traveler_type == "_All_") & port_name == "Otay Mesa East" ~ "COM_GP_OME",
      vehicle_type == "Commercial" & traveler_type == "FAST" & port_name == "Otay Mesa East" ~ "COM_SP_OME",
      TRUE ~ "NA")
    ) %>%
    group_by(orig, dest, hour, core) %>%
    summarise(trips = sum(trips)) %>%
    arrange(hour, orig, dest)
  
  write.csv(trips_df, file = paste0(assignment_dir, "poe_model_trips.csv"), row.names = FALSE)
  
  # combine Northbound Commercial "General" and "Fast" lanes for comparison with observed
  simulated_outcomes_df <- simulated_outcomes_df %>%
    mutate(traveler_type = ifelse((direction == "Northbound" & vehicle_type == "Commercial"), "_All_", traveler_type))
  
  simulated_outcomes_df <- simulated_outcomes_df %>%
    group_by(hour, port_name, direction, vehicle_type, traveler_type) %>%
    summarise(volume = sum(volume),
              port_toll_cost = mean(port_toll_cost),
              median_wait_time = mean(median_wait_time),
              median_process_time = mean(median_process_time),
              open_lanes = sum(open_lanes),
              stacked_lanes = sum(stacked_lanes),
              queue = sum(queue) ,
              processed_volume = sum(processed_volume)
    ) %>%
    mutate(toll = port_toll_cost/100) %>%
    select(hour, port_name, direction, vehicle_type, traveler_type,
           sim_volume = volume, sim_open_lanes = open_lanes, sim_wait_time = median_wait_time, sim_stacked_lanes = stacked_lanes, sim_processed_volume=processed_volume, queue, toll)
  
  # -----------------------------------------------------------------------------------
  # Combine Observed Data
  if(CALIBRATION) {
    observed_data_df <- read.csv(observed_data_file, stringsAsFactors = FALSE)
    
    observed_data_df <- 
      observed_data_df %>%
      select(hour, port_name, direction, vehicle_type, traveler_type, 
             obs_volume = volume, obs_open_lanes = open_lanes, obs_wait_time_CBP = wait_time, obs_wait_time_caltrans = wait_time_caltrans, obs_wait_time_survey = wait_time_survey)
    
    model_results_df <- left_join(observed_data_df, simulated_outcomes_df, by = c("hour", "port_name", "direction", "vehicle_type", "traveler_type"))
    
    summary_df <- 
      model_results_df %>%
      group_by(port_name, vehicle_type, traveler_type, direction) %>%
      summarise(obs_trips = sum(obs_volume), sim_trips = sum(sim_volume), processed_trips=sum(sim_processed_volume))
    
    write.csv(summary_df, paste0(data_out_dir,"summary.csv"))
    
  } else {
    model_results_df <- simulated_outcomes_df
  }
  
  write.csv(model_results_df, paste0(data_out_dir,"poe_results.csv"), row.names = FALSE)
}
