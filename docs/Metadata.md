# Metadata for Otay Mesa Model v2.1 Input and Configurations Files    

This file will provide metadata for the input and configuration files that are used for the Otay Mesa Border Crossing Model. Per the User's Guide, there are 5 sets of files the user must interact with prior to running a scenario. They are listed below: 

- Trip Tables
- Network 
- POE Rate File
- Properties File
- Run Configuration File  


These files are located in the `scenario_inputs` folder.  There is currently a folder of inputs for scenario years 2017 (2017_Base), 2020, 2030 and 2040 as well as a `config` folder.  See the ['user_guide.md'](https://github.com/wsp-sag/sr11_ome_v2/blob/master/docs/user_guide.md) for instructions on how to set up a model run - the files in the scenario_inputs folder need to be copied to the data_in directory for a particular scenario run - this file only discusses the content of the files, not how to use them to run the model. Below is a description of each set of files.  

This document also provides metadata for two additional files that contain model properties and assumptions that are used by the model but do not need to be modified by the User unless the model is being debugged, re-calibrated or assumptions re-evaluated.  

- Port Configuation File  
- Value of Time Segmentation File

These files should be present in the `data_in` directory for a scenario run.  
***

# Metadata for Files in the `scenario_inputs` Directory

## Trip Tables
For each scenario year, there is a set of Trip Tables - one for each hour of the day - that represent privately-owned vehicle (POV) and commercial vehicle (CV) trips between origins (O) and destinations (D) in the study area.  The trip tables include cross-border trips as well as U.S. to U.S. trips and are segmented within each hour by vehicle-type, trip purpose, and lane-type. See ['create_trip_tables.md'](https://github.com/wsp-sag/sr11_ome_v2/blob/master/docs/create_trip_tables.md) that documents the process for creating these trip tables.  

### 2017_Base
`scenario_inputs/2017_Base/Trip_Tables/rds`   
Inside this folder you will see 24 files - Trips_1.RDS through Trips_24.RDS.  Each file represents 5315 x 5315 origin-destination trip matrices saved as a serialized R object [(RDS format)](https://www.rdocumentation.org/packages/base/versions/3.3.2/topics/readRDS?tap_a=5644-dce66f&tap_s=10907-287229). See ['ReadMe.md'](https://github.com/wsp-sag/sr11_ome_v2/blob/master/data_in/ReadMe.md) for the Hour definitions used in the code.    

### 2020
`scenario_inputs/2020/Trip_Tables/rds`   
The trip tables are the same format as 2017_Base and reflect the number of trips estimated in 2020.  

### 2030 
`scenario_inputs/2030/Trip_Tables/2030_Base/rds`, `scenario_inputs/2030/Trip_Tables/2030_Optimistic/rds`, `scenario_inputs/2030/Trip_Tables/2030_Pessimistic/rds`  
As the folder names imply, these 3 tables represent different 2030 scenarios - the Base set reflects the expected 2030 growth based on the growth curves that were developed by the project team.  The optimistic set reflects 10% higher than expected growth and the pessimistic set reflects 10% lower than expected growth. 

### 2040 
`scenario_inputs/2040/Trip_Tables/2040_Base/rds`, `scenario_inputs/2040/Trip_Tables/2040_Optimistic/rds`, `scenario_inputs/2040/Trip_Tables/2040_Pessimistic/rds`  
As the folder names imply, these 3 tables represent different 2040 scenarios - the Base set reflects the expected 2040 growth based on the growth curves that were developed by the project team.  The optimistic set reflects 10% higher than expected growth and the pessimistic set reflects 10% lower than expected growth.  

## Network  
The base year highway network was created by stitching together the 2012 Series SANDAG model network for the U.S. side and a network created using OpenStreetMap to represent the Mexico side. The network attributes 'POE' and 'POE_Lane' provide the information about which POE the link belongs to *(SY = San Ysidro; OM = Otay Mesa; OME = Otay Mesa East)* and what vehicle/lane-type/direction it is *(POV_SE = Privately Owned Vehicle SENTRI; POV_RE = Ready; POV_GP = General Purpose; POV_SB = Southbound; COM_SP = Commercial Vehicle FAST; COM_GP = General Purpose)*.  The Network fields to pay attention to are:  
- Length  
- Dir  
- ABLNO - number of lanes in AB direction, used to calculate capacities on links   
- BALNO - number of lanes in BA direction, used to calculate capacities on links  
- ABPLC - SANDAG per lane capacities, used to calculate capacities on links     
- BAPLC - SANDAG per lane capacities, used to calculate capacities on links  
- ABAU -  SANDAG designation for auxillary lanes, used to add additional capacity over and above the per lane capacity calculation
- BAAU -  SANDAG designation for auxillary lanes, used to add additional capacity over and above the per lane capacity calculation
- IHOV - designates a link as HOV (1=General Purpose, 2=HOV2, 3=HOV3+, 4=Toll), used to calculate capacities links, used to calculate capacities on links  
- AB_Cap - capacity on link, this value is calculated in GISDK code  
- Country - values are "USA" or "Mexico"  
- POE - which port the link belongs to 
- POE_Lane - the vehicle and lane type (see above) 
- IFC* - functional classification - 10 = centroids, 99 & 101 = POE link, < 10 are SANDAG classifications
- ISPD_PK and ISPD_OP - initial speed, peak and off-peak respectively  
- ABFF_TIME_PK and BAFF_TIME_PK**
- AB_TIME_PK, BA_TIME_PK and AB_TIME_OP, BA_TIME_OP - filled during assignment with updated link speeds.  For POE links, the wait time at the border is added to this time to reflect time spent in queue.    

'* The IFC is used as look-up for the ALPHA_ and BETA_ network attributes that can be found in `data_in/Capacity.dbf`.  The Capacity.dbf file and the values in it are a carry-over from the previous modeling effort (HDR) and were not updated during this phase of the project.  The "POECAP" field is NOT used, that is a legacy attribute that no longer needs to be maintained.  

Note: the capacities for the *non*-POE links are initially set via the GISDK code (see "Update Travel Time, Capacity, Alpha and Beta" in run_poe_model.rsc). The capacities for the POE links are a function of the hourly processing rate for a given lane type as well as how many lanes of that type are open and therefore this is set once the port of entry choice logit model, discrete event simulation, lane optimization and toll optimization is done, just prior to the highway assignment routine during each feedback iteration.  

** Similarly the ABFF_TIME_PK, BAFF_TIME_PK, ABFF_TIME_OP, BAFF_TIME_OP for the POE links are updated based on the wait time at the respective port and therefore are updated once the port choice logit model, discrete event simulation, lane optimization and toll optimization is done, just prior to the highway assignment routine during each feedback loop. It is through the capacities and time network attributes that the highway assignment and port choice models are linked.  (See Chapter 3 -  Bi-national Travel Demand Model of the final project report for more details).  

Note: there are two turn penalty files present in the `sr11_ome_v2/data_in` directory.  'tpenalt.dbf' is referenced in the GISDK code [run_poe_model.rsc](https://github.com/wsp-sag/sr11_ome_v2/blob/master/model/run_poe_model.rsc) but it is not used.  The other, 'tpenalr.dbf' is not referenced.  These files were carried over from previous model effort (HDR) but never updated or used.  Finally, in the [run_poe_model.rsc](https://github.com/wsp-sag/sr11_ome_v2/blob/master/model/run_poe_model.rsc) file, there is an array of free-flow times ("FF_TIME") that are used to define the port link times (they align with the port links as defined in the array "process_rate_names") with NO WAIT time added.  These are used in the initial loop and the wait times calculated by the discrete event simulation is added to this free-flow time for subsequent model loops.  

### 2017_Base  
`scenario_inputs/2017_Base/Network`
There is one network inside this folder and it represents the 2017 base year network.  Otay Mesa East is not included in this network so San Ysidro and Otay Mesa are the only Land Ports of Entry (POE) included.  The POEs are represented by multiple links, one for each vehicle/lane-type/border crossing direction combination.    

### 2020  
`scenario_inputs/2020/Network/Build`, `scenario_inputs/2020/Network/No-Build`
The No-build network in this folder is identical to the 2017 base network.  The build network includes Otay Mesa East Port of Entry.  

### 2030
There is no network for 2030 as the WSP project did not include running 2030 scenarios.  

### 2040 
`scenario_inputs/2040/Network/Build`, `scenario_inputs/2040/Network/No-Build`  
The No-build network in this folder is identical to the 2017 base network.  The build network includes Otay Mesa East Port of Entry and some additional roadway projects expected to be completed by 2040.  See "Transportation Networks" in Chapter 1 of the final report for information about projects included).  

## POE Rates File 
There is at least one POE rates file within each scenario year that defines the number of physical lanes present, the starting number of open lanes and the number of vehicles processed by lane type for each model hour.  Certain scenario years have more than 1 POE rates files which will be explained in more detail below. See the ['user_guide.md'](https://github.com/wsp-sag/sr11_ome_v2/blob/master/docs/user_guide.md) for detailed instructions on how to revise the POE Rate file as well as a description of the fields in the files and their expected values.  

### 2017_Base  
`scenario_inputs/2017_Base/POE_Rates/poe_rates_2017_base.csv`
There is a single POE_Rates file in this folder that denotes the base year port configurations for each model hour (1-24).  The processing rates and number of open lanes in this file were defined initially based on CBP reported data but were adjusted slightly during model calibration in order to match wait time profiles and the observed number of processed vehicles per hour at each port.  These adjusted values were used as starting points in future scenario years.  The number of open lanes are changed during the Discrete Event Simulation, lane optimization procedure; however, the processing rates stay the same.  NOTE: there should be 93 columns in each POE rates file - in the 2017_Base file there are only 91 as this scenario was not re-run after a code change that added fields "SY_GP_RE_MAX" and "OM_GP_RE_MAX".  

### 2020  
`scenario_inputs/2020/Network/POE_Rates/poe_rates_2020_10x10_OM_CV13.csv`, `scenario_inputs/2020/Network/POE_Rates/poe_rates_2020_3x3_OM_CV13.csv`, `scenario_inputs/2020/Network/POE_Rates/poe_rates_2020_5x5_OM_CV13.csv`, `scenario_inputs/2020/Network/POE_Rates/poe_rates_2020_5x5_OM_CV16.csv`,  
`scenario_inputs/2020/Network/POE_Rates/poe_rates_2020_nobuild_OM_CV10.csv`, `scenario_inputs/2020/Network/POE_Rates/poe_rates_2020_nobuild_OM_CV13.csv`    
The names of the POE rates file are descriptive.  '10x10' refers to the configuration at OME, i.e. 10 POV lanes, 10 commercial lanes;  'nobuild' means that OME is not present in the network.  'OM_CV13' refers to the configuration of commercial lanes at Otay Mesa, i.e. 13 commercial lanes.  

### 2030
There is no POE_Rates file for 2030 as the WSP project did not include running 2030 scenarios.

### 2040  
`scenario_inputs/2040/Network/POE_Rates/poe_rates_2040_10x10_OM_CV13.csv`, `scenario_inputs/2040/Network/POE_Rates/poe_rates_2040_3x3_OM_CV13.csv`, `scenario_inputs/2040/Network/POE_Rates/poe_rates_2040_5x5_OM_CV13.csv`, `scenario_inputs/2040/Network/POE_Rates/poe_rates_2040_5x5_OM_CV16.csv`,  
 `scenario_inputs/2020/Network/POE_Rates/poe_rates_2020_nobuild_OM_CV13.csv`  
 See 2020 for description of file names.  
 
 ## Properties File 
 `scenario_inputs/config/sr11_ome.properties`
There is a properties file that the model uses to define file paths and several other model assumptions.  Many of the properties in this file do NOT need to be changed but there are some that need to be modified for a particular scenario run.  See "Model Setup, Properties File" in ['user_guide.md'](https://github.com/wsp-sag/sr11_ome_v2/blob/master/docs/user_guide.md) for a description of which properties need to be checked/updated prior to a model run.  Some additional fields not described in the User's Guide as listed in the table below.      

| Property Name          | Description      | Default/Expected Value |
| ---------------------- | -----------------------------| ---------------------------|
| calibration.mode       | defines whether or not user is calibrating the model or not. If TRUE the model will look for the observed data file (optional.observed.data.for.calibration.file.name) and write out the comparison file (optional.output.observed.comparison.file.name) | TRUE or FALSE, FALSE is default|
| convert.trips.to.csv   |deprecated, user should NOT change| 0 = no|
| convert.skims.to.csv   |converts TransCAD formatted skims to csv for futher conversion to RDS, user should NOT change|1 = yes|
|max.xing.time| this is the wait time, in minutes, at Otay Mesa East that the toll value is trying to influence|20|
|max.us.zone.number|if the zone structure changes, this will need to be updated.  It is the largest U.S. zone number|4684|
|warm.start|during calibration, | TRUE or FALSE, FALSE is default| 
|save.results.by.iter|this is for debugging purposes and allows model user to save the results after each iteration.  Often we would see large swings in results between feedback loops and needed to see what was going on.|TRUE or FALSE, FALSE is default|
|trace|another debug feature that allows model user to see the utility and probability calculation in the port choice logit model for a particular OD pair, hour, vehicle type, direction and traveler type|TRUE or FALSE, FALSE is default|
|trace.otaz or trace.dtaz|particular OD pair to trace|use centroid node ID from network to define|
|trace.hour| hour to trace|a number between 1 and 24|
|trace.vehicle.type|vehicle type to trace|'Passenger' or 'Commercial'|
|trace.direction| direction to trace|'Northbound' or 'Southbound'|
|trace.traveler.type|traveler type to trace|Passenger values can be 'General', 'Ready', or 'SENTRI'; Commercial values can be "General" or "FAST"|
||trace values must match the values as defined in ['port_configurations.csv'](https://https://github.com/wsp-sag/sr11_ome_v2/blob/master/data_in/port_configurations.csv)||
|am.peak.start.hour|the start of the morning peak time period, be sure to read the comments above to understand how the hours are defined|number between 1 and 12|
|am.peak.end.hour|the end of the morning peak time period, be sure the start and end are not the same|number between 2 and 12|
|pm.peak.start.hour|the start of the afternoon peak time period, be sure afternoon peak does not conflict with morning definitions|number between 13 and 24|
|pm.peak.end.hour|the end of the afternoon peak time period|number between 14 and 24|  

## Run Configuration File
`scenario_inputs/config/run_config_base_400.csv`,`scenario_inputs/config/run_config_build_400.csv`, `scenario_inputs/config/run_config_nobuild_400.csv` 
The 'run_config' file is used by the Discrete Event Simulation model.  The "base" file is essentially a *template* that the "build" and "nobuild" file is created from.  The "400" in the name refers to the number of iterations that the Discrete Event Simulation (DES) will run.  The fields of the file are described below.    

| File Column Name | Description      | Default/Expected Value |
| ---------------- | -------------------------- | ---------------------------- |
| iter|There will be row for each iteration of the DES| test_value|The scenarios we ran used 400 iterations which we determined to be an appropriate number|
|weight|This is used to average the port wait times over each iteration.  The value should be 1.0 at the last iteration. As an example, the 0.9 in iteration 1 tells model to calculate a weighted average of the wait time using 90% of the initial wait time and 10% of the wait time in iteration 1.  The 0.9 in iteration 2 says use 90% of weighted average after iteration 1 and 10% of iteration 2.  Each subsequent iteration of the DES adds a smaller and smaller percentage of the wait time to the weighted average.  This was done to dampen oscillations in the DES between feedback loops that result from the lane optimization procedure|Recommend keeping these values and following the pattern of increasing every 20 iterations or so|
|do_lane|tells DES whether or not to do the lane optimization procedure for a particular iteration.  We found that doing lane optimization each iteration caused too much oscillation in results.  Optimal was every 20 iterations.|1=true, 0=false|
|do_toll|tells DES whether or not to do the toll optimization procedure. If OME exists and you want toll to be adjusted (i.e. build scenario), then set all iterations to 1.  If OME doesn't exist (i.e. nobuild), or you want to run without a toll, set all iterations to false|1=true, 0=false|  
***

# Metadata for Files in the `data_in` Directory

## Port Configuration File  
`sr11_ome_v2/data_in/port_configurations.csv`  
This file has some default values used by the Discrete Event Simulation and the Port Choice Logit Model. It basically defines the Port of Entry in terms of what types of vehicles pass through, what traveler types it services and some other model parameters.  The fields and their descriptions are below.  

| File Column Name | Description      | Default/Expected Value |
| ---------------- | -------------------------- | ---------------------------- |
|port_name|Name of the Land Port of Entry|San Ysidro, Otay Mesa or Otay Mesa East |
|port_zone|Centroid node ID for the port, use Network to determine these values and note that there are multiple centroids in each port corresponding to vehicle type (Passenger/Commercial) and direction (Northbound/Southbound)|Centroid Node ID numbers from Network|
|vehicle_type|need an entry for each type of vehicle that passes thru the Port.  Not all ports allow Commercial vehicles to pass thru|'Passenger' or 'Commercial'|
|traveler_type|There should be an entry for each traveler_type corresponding to the vehicle_type|Passenger values can be 'General', 'Ready', 'SENTRI', or 'All' for Southbound; Commercial values can be "General", "FAST", or 'All' for Southbound |
|trip_table_suffix|These will match the trip table cores from TransCAD, do NOT change|match the traveler_type|
|direction|The direction of traffic for that particular entry|'Northbound' or 'Southbound'|
|default_toll_in_dollars|Applies only to Otay Mesa East entries.  |Set by project team, can be any number|
|port_choice-bias_constant|Calibrated values used in the Port Choice Logit Model to match base year observed processed vehicles|Will only change if Port Choice Model is re-calibrated|
|initial_queue|Calibration value used to help match wait time profiles in morning hours.  Represents vehicles in the queue that were not processed within the 24 hour model window|Do not change unless model is being re-calibrated |
|min_lanes|Minimum number of lanes for the particular entry|Set by project team based on CBP operating guidelines|


## Value of Time Segmentation  
`sr11_ome_v2/data_in/vot_segmentation.csv`
This file defines the values of time used in the model. They were estimated based on survey data done in the previous phase of this study and while we attempted to determine revised values, in the end, it was determined that these were best available. They represent Year 2017 dollars.  This file will have an entry for each purpose, direction, traveler_type and vehicle_type combination in the model.  Segmentation is consistent with the Trip tables. 

| File Column Name | Description      | Default/Expected Value |
| ---------------- | -------------------------- | ---------------------------- |
|vehicle_type|type of vehicle that passes thru the Port|'Passenger' or 'Commercial'|
|traveler_type|There should be an entry for each traveler_type corresponding to the vehicle_type|Passenger values can be 'General', 'Ready', 'SENTRI', or 'All' for Southbound; Commercial values can be "General", "FAST", or 'All' for Southbound |
|direction|The direction of traffic for that particular entry|'Northbound' or 'Southbound'|
|purpose|Trip Table purposes (see Trip Table section above), Home-based Work, Home-based Other, Home-based Shopping, Loaded or Empty|'HBW', 'HBO', 'HBS', 'Loaded', 'Empty'|
|value_of_time_dollars|The value of time for the particular segment|Any value, be sure it is in base year dollars|
