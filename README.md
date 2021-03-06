# Otay Mesa East Model 3.0

## Repo Background
State Route 11 Otay Mesa East Investment Grade Traffic & Revenue Model Version 3.0.  
This model is an update to model version 2.1 used for the Tier II Innovation Analysis (https://github.com/SANDAG/sr11_ome_v2)


### Model Setup
- Clone the model repo
- Copy scenario specific input data and update config and properties files
	- trip table (.RDS) files goes into `data_in/trip_tables` folder
	- copy poe rate file to the `data_in` folder
	- copy run config and properties file into `config` folder
	- copy skim (.RDS) files into `data_out/skims` folder 
	- scenario specific network goes into `data_in/network` folder.
	- update properties file to local machine setting
	- update run config file for scenario configuration
- Refer to [user's guide](docs/user_guide.md) for more detail
### SANDAG Contact
Rick Curry (Rick.Curry@sandag.org)
### CDM Smith Contact
Cissy Kulakowski (kulakowskics@cdmsmith.com)
