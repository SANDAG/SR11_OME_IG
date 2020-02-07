import pandas as pd
import os
import numpy as np

os.getcwd()

runs = pd.read_csv('config/model_run_ids.csv')
runs = runs[runs.use == 'yes']

data = pd.DataFrame([])
for index, row in runs.iterrows():
    print(row['folder'])
    file_folder = 'T:\\projects\\sr12\\OWP\\sr11ome\\runs\\' + row['root'] + '\\' + row['folder']
    filename = file_folder + '\\data_out\\' + 'poe_results.csv'
    print(filename)
    df = pd.read_csv(filename)
    df1 = df[df.vehicle_type == 'Passenger']
    df1 = df1[df1.traveler_type != '_All_']
    df1['run'] = row['folder']
    df1['run_id'] = row['runid']
    data = data.append(df1)

# PIVOT data for power bi report
#################################################################################
# sim volume
table_volume = pd.pivot_table(data, values='sim_volume', index=['hour','port_name', 'direction','vehicle_type','run','run_id'],
                  columns=['traveler_type'], aggfunc=np.sum)
table_volume.reset_index(inplace=True)
table_volume.rename(columns={'General': 'General:volume', 'Ready': 'Ready:volume',
                                 'SENTRI': 'SENTRI:volume'}, inplace=True)
#################################################################################
#################################################################################
# sim wait times
table_wait = pd.pivot_table(data, values='sim_wait_time', index=['hour', 'port_name', 'direction', 'vehicle_type','run','run_id'],
                            columns=['traveler_type'], aggfunc=np.sum)
table_wait.reset_index(inplace=True)
table_wait.rename(columns={'General': 'General:wait time', 'Ready': 'Ready:wait time',
                           'SENTRI': 'SENTRI:wait time'}, inplace=True)
#################################################################################
#################################################################################
# sim open lanes
table_open_lanes = pd.pivot_table(data, values='sim_open_lanes', index=['hour', 'port_name', 'direction', 'vehicle_type','run','run_id'],
                            columns=['traveler_type'], aggfunc=np.sum)
table_open_lanes.reset_index(inplace=True)
table_open_lanes.rename(columns={'General': 'General:open lanes', 'Ready': 'Ready:open lanes',
                           'SENTRI': 'SENTRI:open lanes'}, inplace=True)
#################################################################################
#################################################################################
# sim toll
table_toll = pd.pivot_table(data, values='toll', index=['hour', 'port_name', 'direction', 'vehicle_type','run','run_id'],
                            columns=['traveler_type'], aggfunc=np.sum)
table_toll.reset_index(inplace=True)
table_toll.rename(columns={'General': 'General:toll', 'Ready': 'Ready:toll',
                           'SENTRI': 'SENTRI:toll'}, inplace=True)
#################################################################################
result = pd.merge(table_volume, table_wait, on=['hour', 'port_name', 'direction', 'vehicle_type','run','run_id'])
result = pd.merge(result, table_open_lanes, on=['hour', 'port_name', 'direction', 'vehicle_type','run','run_id'])
result = pd.merge(result, table_toll, on=['hour', 'port_name', 'direction', 'vehicle_type','run','run_id'])

output_directory = '../run_data'
if not os.path.exists(output_directory):
    os.makedirs(output_directory)

result.to_csv(output_directory + '/poe_volume_wait_times_for_powerbi.csv',index=False)


