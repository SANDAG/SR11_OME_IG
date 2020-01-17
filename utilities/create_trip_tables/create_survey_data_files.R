list_of_packages <- c("tidyverse")
new_packages <- list_of_packages[!(list_of_packages %in% installed.packages()[,"Package"])]
if(length(new_packages)) install.packages(new_packages)

for (package in list_of_packages){
  library(package, character.only = TRUE)
}

base_year_survey_files_path <- "C:/Projects/SANDAG/Otay_Mesa/sr11_ome_v2/utilities/create_trip_tables/survey_data/"

pv_nb_scaling_factor <- 1.10233
pv_sb_scaling_factor <- 1.10233
cv_nb_scaling_factor <- 1.08658
cv_sb_scaling_factor <- 1.20900

scenario_year <- "2020"

output_path <- "C:/Projects/SANDAG/Otay_Mesa/sr11_ome_v2/utilities/create_trip_tables/2020/"

#############################################
### DO NO CHANGE ANYTHING BELOW THIS LINE ###
#############################################

pv_data_file <- "OD_Survey_2017.csv"
cv_data_file <- "Truck_Trips_2017.csv"

pv_base_data_df <- read.csv(paste0(base_year_survey_files_path, pv_data_file))
cv_base_data_df <- read.csv(paste0(base_year_survey_files_path, cv_data_file))

pv_sce_data_df <- pv_base_data_df %>%
  mutate(RevWght = ifelse(Dir == "NB", RevWght * pv_nb_scaling_factor, RevWght * pv_sb_scaling_factor))

cv_sce_data_df <- cv_base_data_df %>%
  mutate(RevWght = ifelse(Dir == "NB", RevWght * cv_nb_scaling_factor, RevWght * cv_sb_scaling_factor))

if (!dir.exists(output_path))
  dir.create(output_path)

write.csv(pv_sce_data_df, paste0(output_path, "OD_Survey_", scenario_year, ".csv"), row.names = FALSE)
write.csv(cv_sce_data_df, paste0(output_path, "Truck_Trips_", scenario_year, ".csv"), row.names = FALSE)