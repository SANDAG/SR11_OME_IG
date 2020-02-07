

# Overall Description

Run the python script to aggregate all the data from individual runs into one csv file with all the output.
Load the output file from the python script to Power BI. 
An individual run and port may be selected in the Power BI filter.
Each tab in Power BI has a separate plot.


# Files

All files are located in sr11_ome_v2/powerbi

* Python script:	'scripts/sr11_ome_v2_powerbi.py' (python script to aggregate output)
* Config file:		'scripts/config/model_run_ids.csv' (list of output files to visualize) 
* Power BI:			'sr11_ome_v2.pbix' (Power BI file)

# Process

Here are the steps to follow to update Power BI with a new run:

1. Edit the config file:
				'scripts/config/model_run_ids.csv'.  
		Each row contains a run.  Add new runs to the bottom of the file. 
		Enter yes/no in the column 'use' to specify whether a run in Power BI should be available in the filter.

2. Run the python script:
				'scripts/sr11_ome_v2_powerbi.py'  
		Note: This will create a folder 'run_data' containing the aggregated data file, 'poe_volume_wait_times_for_powerbi.csv'


3. Open the Power BI file in Power BI Desktop: 
				'sr11_ome_v2.pbix'
				

4. Click Refresh in the Power BI ribbon.  
		This will automatically reload the file 'poe_volume_wait_times_for_powerbi.csv' (that was just generated with new run data)

5. Save the Power BI file. Close Power BI desktop.

6. Go to the Power BI app (https://app.powerbigov.us/home)

7. Go to the Border Team Workspace

8. Click on Reports

9. Click on Get data (bottm left of page)

10. Click on Files.  Click on Local File.  Navigate to the Power BI file that was just edited: 'sr11_ome_v2.pbix'

11. Click on Replace the existing file.

12. Check that the file has been updated in the Power BI tab on Microsoft Teams for the Border Team. 


