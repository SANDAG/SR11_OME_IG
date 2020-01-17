list_of_packages <- c("tidyverse", "data.table")
new_packages <- list_of_packages[!(list_of_packages %in% installed.packages()[,"Package"])]
if(length(new_packages)) install.packages(new_packages)

for (package in list_of_packages){
  library(package, character.only = TRUE)
}

out_dir <- "C:/Projects/SANDAG/Otay_Mesa/sr11_ome_v2/utilities/create_trip_tables/2020/"

csv_dir <- paste0(out_dir, "/csv/")
rds_dir <- paste0(out_dir, "/rds/")

TransCAD_Trip_CSV_Matrix_to_R <- function(input_csv_matrix_file, input_dcc_matrix_file, output_r_dataframe_file, input_desired_cols){

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

desired_non_zero_trip_table_vector <- c("HBO_General", "HBO_Ready", "HBO_SENTRI", 
                                        "HBW_General", "HBW_Ready", "HBW_SENTRI", 
                                        "HBS_General", "HBS_Ready", "HBS_SENTRI",
                                        "Loaded_GP", "Loaded_FAST", "Empty_GP", "Empty_FAST") 

for (hour_of_day in 1:24){
  tc_csv_mtx_file <- sprintf(paste0(csv_dir, "Trips_%d.CSV"), hour_of_day)
  tc_dcc_mtx_file <- sprintf(paste0(csv_dir, "Trips_%d.DCC"), hour_of_day)
  r_df_file <- sprintf(paste0(rds_dir, "Trips_%d.RDS"), hour_of_day)
  
  TransCAD_Trip_CSV_Matrix_to_R(tc_csv_mtx_file, tc_dcc_mtx_file, r_df_file, desired_non_zero_trip_table_vector) 
}

