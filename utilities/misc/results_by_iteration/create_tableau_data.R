library(tidyverse)
library(data.table)

output_dir <- "C:/Projects/SANDAG/Otay_Mesa/sr11_ome_v3/data_out/debug/"
iterations <- 600

if (exists("port_of_entry_demand_df_all")) remove(port_of_entry_demand_df_all)

# save results of all iterations in one file
for(iter in 1:iterations){
  if(iter%%25 == 0) print(paste0("Reading Iteration # ", iter, " ..."))
  
  work_df <- fread(paste0(output_dir, "port_of_entry_demand_df_", iter, ".csv"))
  work_df <- work_df %>% mutate(iteration = iter)
  if (exists("port_of_entry_demand_df_all")) {
    port_of_entry_demand_df_all <- bind_rows(port_of_entry_demand_df_all, work_df)
  } else {
    port_of_entry_demand_df_all <- work_df
  }
}

data_all_df <- port_of_entry_demand_df_all %>%
  group_by(direction, vehicle_type, traveler_type, port_name, hour, iteration) %>%
  summarise(volume = sum(trips), port_time = mean(port_time), des_pre = mean(des_pre_lane),
            lanes = mean(open_lanes), des_post = mean(des_post_lane), port_toll = max(port_toll_cost))

write.csv(data_all_df, paste0(output_dir, "data_all_df.csv"), row.names = FALSE)

if(file.exists(paste0(output_dir, "port_entry_rates_df.csv"))) file.remove(paste0(output_dir, "port_entry_rates_df.csv"))
file.copy(paste0(output_dir, "port_entry_rates_df_", iterations, ".csv"), paste0(output_dir, "port_entry_rates_df.csv"))
