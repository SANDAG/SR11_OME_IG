Macro "CreateTripTables" 
  RunMacro("TCB Init")
  
  auto_file = "C:\\Projects\\SANDAG\\Otay_Mesa\\sr11_ome_v2\\utilities\\create_trip_tables\\2020\\OD_Survey_2020.csv"	
  truck_file = "C:\\Projects\\SANDAG\\Otay_Mesa\\sr11_ome_v2\\utilities\\create_trip_tables\\2020\\Truck_Trips_2020.csv"	

  out_dir = "C:\\Projects\\SANDAG\\Otay_Mesa\\sr11_ome_v2\\utilities\\create_trip_tables\\2020"
  
  mtx_dir = out_dir + "\\mtx"
  csv_dir = out_dir + "\\csv"
  rds_dir = out_dir + "\\rds"

  if GetDirectoryInfo(out_dir, "Folder") = Null then CreateDirectory(out_dir)
  if GetDirectoryInfo(mtx_dir, "Folder") = Null then CreateDirectory(mtx_dir)
  if GetDirectoryInfo(csv_dir, "Folder") = Null then CreateDirectory(csv_dir)
  if GetDirectoryInfo(rds_dir, "Folder") = Null then CreateDirectory(rds_dir)
  
  // convert survey data to TransCAD matrices
  RunMacro("CreateMTX", auto_file, truck_file, mtx_dir)

  // convert mtx to csv
  RunMacro("CreateCSV", mtx_dir, csv_dir)
  
  ShowMessage("finished!") 
EndMacro


Macro "CreateMTX" (pov_file, com_file, mtx_dir)
	Purpose = {"HBO", "HBW", "HBS"}
	Lane = {"General", "Ready", "SENTRI"}

	// Hour      1   2   3   4   5   6   7   8   9  10  11  12  13  14  15  16  17  18  19  20  21  22  23  24
	Do_Truck = {no, no, no, no, no,yes,yes,yes,yes,yes,yes,yes,yes,yes,yes,yes,yes,yes,yes,yes,yes,yes, no, no}
	Truck_Purpose = {"Loaded", "Empty"}
	Truck_Lane = {"GP", "FAST"}
		
	Counter = 1
	Dim table_list[13]
	Dim csv_list[13]
	Dim query_list[13]
	
	//Create POV Table List
	For p = 1 to Purpose.length do
		For l = 1 to Lane.length do
			table_list[Counter] = Purpose[p] + "_" + Lane[l]
			csv_list[Counter] = pov_file
			lane_str = Lane[l]
			query_list[Counter] = 'Select * where Purpose = "' + Purpose[p] + '" and Lane = "' + lane_str + '"'
			Counter = Counter + 1
		End
	End

	//Create Truck Table List
	For p = 1 to Truck_Purpose.length do
		For l = 1 to Truck_Lane.length do
			table_list[Counter] = Truck_Purpose[p] + "_" + Truck_Lane[l]
			csv_list[Counter] = com_file
			query_list[Counter] = 'Select * where Type = "' + Truck_Purpose[p] + '" and Lane = "' + Truck_Lane[l] + '"'
			Counter = Counter + 1
		End
	End	
	
	For z = 1 to 24 do
		mtx_file = mtx_dir + "\\" + "Trips_" + String(z) + ".mtx"
		
		m1 = CreateMatrixFromScratch("POE Trips",5315,5315,{{"File Name",mtx_file},{"Label","Trips"},
	{"Type","Float"},{"Tables",table_list},{"Compression",True}})
	
		For i = 1 to ArrayLength(table_list) do
			//Open the trip table for conversion to matrix format
			
			table_vw = OpenTable("Data", "CSV", { csv_list[i], null})
			SetView(table_vw)
			n_sel = SelectByQuery ("Selection", "Several", query_list[i] + " and ArHour = " + String(z), )
			
			matrix_name = table_list[i]
			mc = CreateMatrixCurrency(m1, matrix_name, "Row Index", "Column Index",)
			table_set = table_vw+"|Selection"
			rec = GetFirstRecord(table_set, null)
			while rec <> null do
				old_value = GetMatrixValue(mc, string(table_vw.FromZone), string(table_vw.ToZone))
				if (old_value = null) then old_value = 0
				new_value = old_value + table_vw.RevWght
				SetMatrixValue (mc, string(table_vw.FromZone), string(table_vw.ToZone), new_value)
				rec = GetNextRecord(table_set, null, null)
			end

			CloseView(table_vw)

		End
	End

EndMacro

Macro "CreateCSV" (mtx_dir, csv_dir)
  for hour = 1 to 24 do
  	matrix_file = mtx_dir + "\\" + "Trips_" + String(hour) + ".mtx"
  	csv_file = csv_dir + "\\" + "Trips_" + String(hour) + ".csv"
  	
  	mat = OpenMatrix(matrix_file, )
  	mat_cores = GetMatrixCoreNames(mat)
    CreateTableFromMatrix(mat, csv_file, "CSV", {{"Complete", "No"}, {"Tables", mat_cores}})
    mat = null

  end
EndMacro