/*
SR11 OME POE Model
Model v 3.0

TransCAD:
Version 6.0
Model Developed on Build 9215 
Model Ran on Builds 9215 and 9065

Original Author:
Ashish Kulshrestha
WSP
ashish.kulshrestha@wsp.com
*/

Macro "POEModel"
	RunMacro("TCB Init")
	
	max_iter = 3
		
	property_file = "C:\\Projects\\sr11_ome_IG\\config\\sr11_ome.properties"
	
	// read properties
	model_dir = RunMacro("ReadProperty", property_file, "model.dir", "s")
	source_dir = RunMacro("ReadProperty", property_file, "source.dir", "s")
	r_program_path = RunMacro("ReadProperty", property_file, "r.program.path", "s")
	do_ome = RunMacro("ReadProperty", property_file, "do.ome", "i")
	poe_rate_file_name = RunMacro("ReadProperty", property_file, "poe.rate.file.name", "s")
	network_file_name = RunMacro("ReadProperty", property_file, "network.file.name", "s")
	
	am_peak_start_hour = RunMacro("ReadProperty", property_file, "am.peak.start.hour", "i")
	am_peak_end_hour = RunMacro("ReadProperty", property_file, "am.peak.end.hour", "i")
	pm_peak_start_hour = RunMacro("ReadProperty", property_file, "pm.peak.start.hour", "i")
	pm_peak_end_hour = RunMacro("ReadProperty", property_file, "pm.peak.end.hour", "i")
	
	convert_trips_to_csv = RunMacro("ReadProperty", property_file, "convert.trips.to.csv", "i")
	convert_skims_to_csv = RunMacro("ReadProperty", property_file, "convert.skims.to.csv", "i")
	
	trips_dir = RunMacro("ReadProperty", property_file, "trips.dir", "s")
	skims_dir = RunMacro("ReadProperty", property_file, "skims.dir", "s")
	assignment_dir = RunMacro("ReadProperty", property_file, "assignment.dir", "s")
	network_file_name = RunMacro("ReadProperty", property_file, "network.file.name", "s")

  // input files
	highway_layer = Substitute(model_dir + network_file_name, "/", "\\", )
  poe_rates_table = Substitute(model_dir + poe_rate_file_name, "/", "\\", )
  turn_penalty_type = Substitute(model_dir + "data_in/" + "tpenalt.dbf", "/", "\\", )
  capacity_table = Substitute(model_dir + "data_in/" + "Capacity.dbf", "/", "\\", )

  LANE_TYPE = {"POV_GP","POV_RE","POV_SE","POV_SB","COM_GP","COM_SP","COM_SB"}

	if(do_ome) then do
  	cnt_poe_links = 18
  	
  	POE_NAME = {"SY","OM","OME"}  	
  	FF_TIME = {7.2, 6.52, 6.12, 6.12, 7.2, 6.52, 6.12, 6.12, 12, 10, 8, 7.2, 6.52, 6.12, 6.12, 12, 10, 8}
  	process_rate_names = {"SY_GP_VEH","SY_RE_VEH","SY_SE_VEH","SY_SB_VEH","OM_GP_VEH","OM_RE_VEH","OM_SE_VEH","OM_SB_VEH","OMC_GP_VEH","OMC_SP_VEH","OMC_SB_VEH","OME_GP_VEH","OME_RE_VEH","OME_SE_VEH","OME_SB_VEH","OMEC_GP_VEH","OMEC_SP_VEH","OMEC_SB_VEH"}
    lane_names = {"SY_GP_OPEN","SY_RE_OPEN","SY_SE_OPEN","SY_SB_OPEN","OM_GP_OPEN","OM_RE_OPEN","OM_SE_OPEN","OM_SB_OPEN","OMC_GP_OPEN","OMC_SP_OPEN","OMC_SB_OPEN","OME_GP_OPEN","OME_RE_OPEN","OME_SE_OPEN","OME_SB_OPEN","OMEC_GP_OPEN","OMEC_SP_OPEN","OMEC_SB_OPEN"}
  	max_lane_names = {"SY_GP_MAX","SY_RE_MAX","SY_SE_MAX","SY_SB_MAX","OM_GP_MAX","OM_RE_MAX","OM_SE_MAX","OM_SB_MAX","OMC_GP_MAX","OMC_SP_MAX","OMC_SB_MAX","OME_GP_MAX","OME_RE_MAX","OME_SE_MAX","OME_SB_MAX","OMEC_GP_MAX","OMEC_SP_MAX","OMEC_SB_MAX"}
    stack_rate_names = {"SY_GP_STV","SY_RE_STV","SY_SE_STV","SY_SB_STV","OM_GP_STV","OM_RE_STV","OM_SE_STV","OM_SB_STV","OMC_GP_STV","OMC_SP_STV","OMC_SB_STV","OME_GP_STV","OME_RE_STV","OME_SE_STV","OME_SB_STV","OMEC_GP_STV","OMEC_SP_STV","OMEC_SB_STV"}
  	stack_lane_names = {"SY_GP_STL","SY_RE_STL","SY_SE_STL","SY_SB_STL","OM_GP_STL","OM_RE_STL","OM_SE_STL","OM_SB_STL","OMC_GP_STL","OMC_SP_STL","OMC_SB_STL","OME_GP_STL","OME_RE_STL","OME_SE_STL","OME_SB_STL","OMEC_GP_STL","OMEC_SP_STL","OMEC_SB_STL"}
  end
	else do
    cnt_poe_links = 11

  	POE_NAME = {"SY","OM"} 	
  	FF_TIME = {7.2, 6.52, 6.12, 6.12, 7.2, 6.52, 6.12, 6.12, 12, 10, 8}
  	process_rate_names = {"SY_GP_VEH","SY_RE_VEH","SY_SE_VEH","SY_SB_VEH","OM_GP_VEH","OM_RE_VEH","OM_SE_VEH","OM_SB_VEH","OMC_GP_VEH","OMC_SP_VEH","OMC_SB_VEH"}
  	lane_names = {"SY_GP_OPEN","SY_RE_OPEN","SY_SE_OPEN","SY_SB_OPEN","OM_GP_OPEN","OM_RE_OPEN","OM_SE_OPEN","OM_SB_OPEN","OMC_GP_OPEN","OMC_SP_OPEN","OMC_SB_OPEN"}
  	max_lane_names = {"SY_GP_MAX","SY_RE_MAX","SY_SE_MAX","SY_SB_MAX","OM_GP_MAX","OM_RE_MAX","OM_SE_MAX","OM_SB_MAX","OMC_GP_MAX","OMC_SP_MAX","OMC_SB_MAX"}
		stack_rate_names = {"SY_GP_STV","SY_RE_STV","SY_SE_STV","SY_SB_STV","OM_GP_STV","OM_RE_STV","OM_SE_STV","OM_SB_STV","OMC_GP_STV","OMC_SP_STV","OMC_SB_STV"}
  	stack_lane_names = {"SY_GP_STL","SY_RE_STL","SY_SE_STL","SY_SB_STL","OM_GP_STL","OM_RE_STL","OM_SE_STL","OM_SB_STL","OMC_GP_STL","OMC_SP_STL","OMC_SB_STL"}  
  end
  
  dim wait_time[24,3,7]
  dim rates[24]
	dim stk_rates[24]
	dim max_lanes[24]
	dim open_lanes[24]	
	dim lanes[24]	
	dim stk_lanes[24]
	
  for hour = 1 to 24 do
    // read poe rate input file
    ptype = RunMacro("G30 table type", poe_rates_table)
    pth = SplitPath(poe_rates_table)
    ratevw = OpenTable(pth[3], ptype, {poe_rates_table})
    
    rh = LocateRecord(ratevw + "|","TIME",{hour},{{"Exact","True"}})
    process_rates_vals = GetRecordValues(ratevw,rh,process_rate_names)
    stck_rates_vals = GetRecordValues(ratevw,rh,stack_rate_names)
    max_lanes_vals = GetRecordValues(ratevw,rh,max_lane_names)
    open_lanes_vals = GetRecordValues(ratevw,rh,lane_names)
    lanes_vals = GetRecordValues(ratevw,rh,lane_names)
    stk_lanes_vals = GetRecordValues(ratevw,rh,stack_lane_names)
    
    for i = 1 to process_rate_names.length do
    	rates[hour] = rates[hour] + {process_rates_vals[i][2]}
    	stk_rates[hour] = stk_rates[hour] + {stck_rates_vals[i][2]}
    	max_lanes[hour] = max_lanes[hour] + {max_lanes_vals[i][2]}
    	open_lanes[hour] = open_lanes[hour] + {open_lanes_vals[i][2]}
    	lanes[hour] = lanes[hour] + {lanes_vals[i][2]}
    	stk_lanes[hour] = stk_lanes[hour] + {stk_lanes_vals[i][2]}
    end  
    CloseView(ratevw)   
  end  
  
  map = RunMacro("G30 new map", highway_layer, "False")
  layers = GetDBlayers(highway_layer)
  nlayer = layers[1]
  llayer = layers[2]
  db_nodelyr = highway_layer + "|" + nlayer
  db_linklyr = highway_layer + "|" + llayer

  SetLayer(llayer)
  SetView(llayer)

  // add network fields if not already present!
  RunMacro("AddFields", llayer, {"ABFF_TIME_PK", "BAFF_TIME_PK", "ABFF_TIME_OP", "BAFF_TIME_OP"}, {"r", "r", "r", "r"})
  RunMacro("AddFields", llayer, {"AB_TIME_PK", "BA_TIME_PK", "AB_TIME_OP", "BA_TIME_OP"}, {"r", "r", "r", "r"})

  // Update Travel Time, Capacity, Alpha and Beta 
  cap_table = OpenTable("Capacity","DBASE", {capacity_table})
  CAPlink = CreateExpression(cap_table, "CAPlink", "String(FUNCCODE)", )
  LYRlink = CreateExpression(llayer, "AB_Link", "String(IFC)", )
  CAPView = JoinViews("CapView", llayer + ".AB_Link", "CAPACITY.CAPlink", )
  
  rec = GetFirstRecord(CAPView + "|",)
  while rec <> null do
    _Alpha = CAPView.F_ALPHA
    _Beta  = CAPView.F_BETA
    
    // unlimited capacity on centroid links
    if CAPView.IFC = 10 then do
      _AB_Cap = 9999
      _BA_Cap = 9999 

      _ABFF_TIME_PK = CAPView.Length/ CAPView.ISPD_PK * 60
      _BAFF_TIME_PK = CAPView.Length/ CAPView.ISPD_PK * 60
      
      _ABFF_TIME_OP = CAPView.Length/ CAPView.ISPD_OP * 60
      _BAFF_TIME_OP = CAPView.Length/ CAPView.ISPD_OP * 60
      
      SetRecordValues(CAPView,rec,{{"AB_Cap",_AB_Cap},{"BA_CAP",_BA_Cap},{"ALPHA_",_Alpha},{"BETA_",_Beta},{"ABFF_TIME_PK",_ABFF_TIME_PK},{"BAFF_TIME_PK",_BAFF_TIME_PK},{"ABFF_TIME_OP",_ABFF_TIME_OP},{"BAFF_TIME_OP",_BAFF_TIME_OP},{"AB_TIME_PK",_ABFF_TIME_PK},{"BA_TIME_PK",_BAFF_TIME_PK},{"AB_TIME_OP",_ABFF_TIME_OP},{"BA_TIME_OP",_BAFF_TIME_OP}})
    end

    if CAPView.IFC > 10 then do
      _ABFF_TIME_PK = CAPView.Length/ CAPView.ISPD_PK * 60
      _BAFF_TIME_PK = CAPView.Length/ CAPView.ISPD_PK * 60
      
      _ABFF_TIME_OP = CAPView.Length/ CAPView.ISPD_OP * 60
      _BAFF_TIME_OP = CAPView.Length/ CAPView.ISPD_OP * 60
      
      SetRecordValues(CAPView,rec,{{"ALPHA_",_Alpha},{"BETA_",_Beta},{"ABFF_TIME_PK",_ABFF_TIME_PK},{"BAFF_TIME_PK",_BAFF_TIME_PK},{"ABFF_TIME_OP",_ABFF_TIME_OP},{"BAFF_TIME_OP",_BAFF_TIME_OP},{"AB_TIME_PK",_ABFF_TIME_PK},{"BA_TIME_PK",_BAFF_TIME_PK},{"AB_TIME_OP",_ABFF_TIME_OP},{"BA_TIME_OP",_BAFF_TIME_OP}})
    end
    
    if CAPView.IFC < 10 then do
      if CAPView.Dir = 1  then _AB_Cap = ((CAPView.ABLNO * CAPView.ABPLC + CAPView.ABAU * 1200) * 1.05)  //SANDAG Capacity/Lane
      if CAPView.Dir = -1 then _BA_Cap = ((CAPView.BALNO * CAPView.BAPLC + CAPView.BAAU * 1200) * 1.05)  //SANDAG Capacity/Lane
      if CAPView.Dir = 0  then _AB_Cap = ((CAPView.ABLNO * CAPView.ABPLC + CAPView.ABAU * 1200) * 1.05)  //SANDAG Capacity/Lane
      if CAPView.Dir = 0  then _BA_Cap = ((CAPView.BALNO * CAPView.BAPLC + CAPView.BAAU * 1200) * 1.05)  //SANDAG Capacity/Lane
      
      if CAPView.IHOV > 1 and CAPView.Dir = 1 then _AB_Cap = _AB_Cap + (1600 * CAPView.ABLNO)   //Adjustment for HOV lane, 1600 lane capacity/hour
      if CAPView.IHOV > 1 and CAPView.Dir = -1 then _BA_Cap = _AB_Cap + (1600 * CAPView.ABLNO)  //Adjustment for HOV lane, 1600 lane capacity/hour
      
      if CAPView.Dir = 1  then _ABFF_TIME_PK = CAPView.Length/ CAPView.ISPD_PK * 60 //AB Time populated on active links
      if CAPView.Dir = -1 then _BAFF_TIME_PK = CAPView.Length/ CAPView.ISPD_PK * 60 //BA Time populated on active links
      if CAPView.Dir = 0  then _ABFF_TIME_PK = CAPView.Length/ CAPView.ISPD_PK * 60 //AB Time on bi-directional links
      if CAPView.Dir = 0  then _BAFF_TIME_PK = CAPView.Length/ CAPView.ISPD_PK * 60 //BA Time on bi-directional links
      
      if CAPView.Dir = 1  then _ABFF_TIME_OP = CAPView.Length/ CAPView.ISPD_OP * 60 //AB Time populated on active links
      if CAPView.Dir = -1 then _BAFF_TIME_OP = CAPView.Length/ CAPView.ISPD_OP * 60 //BA Time populated on active links
      if CAPView.Dir = 0  then _ABFF_TIME_OP = CAPView.Length/ CAPView.ISPD_OP * 60 //AB Time on bi-directional links
      if CAPView.Dir = 0  then _BAFF_TIME_OP = CAPView.Length/ CAPView.ISPD_OP * 60 //BA Time on bi-directional links
      
      SetRecordValues(CAPView,rec,{{"AB_Cap",_AB_Cap},{"BA_CAP",_BA_Cap},{"ALPHA_",_Alpha},{"BETA_",_Beta},{"ABFF_TIME_PK",_ABFF_TIME_PK},{"BAFF_TIME_PK",_BAFF_TIME_PK},{"ABFF_TIME_OP",_ABFF_TIME_OP},{"BAFF_TIME_OP",_BAFF_TIME_OP},{"AB_TIME_PK",_ABFF_TIME_PK},{"BA_TIME_PK",_BAFF_TIME_PK},{"AB_TIME_OP",_ABFF_TIME_OP},{"BA_TIME_OP",_BAFF_TIME_OP}})
    end

    _Alpha = null
    _Beta = null
    _AB_Cap = null
    _BA_Cap = null
    _ABFF_TIME_PK = null
    _BAFF_TIME_PK = null
    _ABFF_TIME_OP = null
    _BAFF_TIME_OP = null

    rec = GetNextRecord(CAPView + "|",rec,)
  end    // end of while loop

  RunMacro("Close All")    
  
	if convert_trips_to_csv then RunMacro("ConvertTripsToCSV", model_dir, trips_dir)
	  
	iteration = 0
	converged = 0
	 
	log_file = model_dir + "config/run_log.txt"
	if(GetFileInfo(log_file) <> null) then DeleteFile(log_file)
	
	While converged = 0 do
		iteration = iteration + 1
		
		//write log
		f = OpenFile(log_file,"a")
    line = "Running integrated model iteration " + String(iteration) + " ... " + GetDateAndTime()
    WriteLine(f, line)
    CloseFile(f)

    For hour = 1 to 24 do
      network_file = model_dir + skims_dir + "network_" + string(hour) + ".net"
      network_file = Substitute(network_file, "/", "\\", )
      skim_mat = model_dir + skims_dir + "Skims_" + string(hour) + ".mtx"
      skim_mat = Substitute(skim_mat, "/", "\\", )
      
      map = RunMacro("G30 new map", highway_layer, "False")
      layers = GetDBlayers(highway_layer)
      nlayer = layers[1]
      llayer = layers[2]
      SetLayer(llayer)
      
      // update link congested time from previous assignment
      // first iteration use FFT as congested time. second iteration onwards, time fields are updated with congested time from assignment
      if(iteration > 1) then do
        assignment_table = model_dir + assignment_dir + "assign_" + string(hour) + ".bin"
        assignment_table = Substitute(assignment_table, "/", "\\", )
        asntab = OpenTable("asntab", "FFB", {assignment_table})

        // get congested time
        {abtime, batime} = GetDataVectors(asntab + "|", {"AB_Time", "BA_Time"}, {{"Sort Order", {{"ID1","Ascending"}}}})
        
        SetDataVector(llayer + "|", "AB_Time_PK", abtime, {{"Sort Order",{{"ID","Ascending"}}}})
        SetDataVector(llayer + "|", "BA_Time_PK", batime, {{"Sort Order",{{"ID","Ascending"}}}})
        SetDataVector(llayer + "|", "AB_Time_OP", abtime, {{"Sort Order",{{"ID","Ascending"}}}})
        SetDataVector(llayer + "|", "BA_Time_OP", batime, {{"Sort Order",{{"ID","Ascending"}}}})
      end
      
      // update POE links capacity, travel time etc.
	    counter = 1
	    For i = 1 to POE_NAME.Length do
	    	For j = 1 to LANE_TYPE.Length do
	    		SetView(llayer)
	    		set_sql = "Select * where POE = '" + POE_NAME[i] + "' and POE_Lane = '" + LANE_TYPE[j] + "'"
	    		n2 = SelectByQuery(POE_NAME[i] + "_" + LANE_TYPE[j],"Several",set_sql,)
	    		if n2 > 0 then do						
	    			rec = GetFirstRecord(llayer + "|" + POE_NAME[i] + "_" + LANE_TYPE[j],)
	    			
	    			if open_lanes[hour][counter] = 0 then do
	    				lanes[hour][counter] = 0
      	  		stk_lanes[hour][counter] = 0
      			end
      				
	    			if lanes[hour][counter] = 0 then Adj_TIME = 9999 
	    			else Adj_TIME = FF_TIME[counter] + Nz(wait_time[hour][i][j])	
	    			
	    			adj_cap = Max((rates[hour][counter] * (lanes[hour][counter]-stk_lanes[hour][counter]))+(stk_rates[hour][counter] * stk_lanes[hour][counter]),1)
	    			
	    			SetRecordValues(llayer,rec,{{"ABFF_TIME_PK",Adj_TIME},{"BAFF_TIME_PK",Adj_TIME},{"ABFF_TIME_OP",Adj_TIME},{"BAFF_TIME_OP",Adj_TIME},{"AB_Cap",adj_cap},{"ABLNO",lanes[hour][counter]}})
	    			counter = counter + 1
	    		end
	    	end
	    end 
      
      // set the hour as peak/off-peak. pk_hour = 1 is PK period; pk_hour = 0 is OP period
      pk_hour = 0
      if(hour >= am_peak_start_hour and hour <= am_peak_end_hour) then pk_hour = 1
      if(hour >= pm_peak_start_hour and hour <= pm_peak_end_hour) then pk_hour = 1
    
      // Build Highway Network
      Opts = null
      Opts.Input.[Link Set] = {db_linklyr, llayer}
      Opts.Global.[Network Options].[Link Type] = {"IFC", llayer + ".IFC", llayer + ".IFC"}
      Opts.Global.[Network Options].[Node ID] = nlayer + ".ID"
      Opts.Global.[Network Options].[Link ID] = llayer + ".ID"
      Opts.Global.[Network Options].[Keep Duplicate Links] = "FALSE"
      Opts.Global.[Network Options].[Ignore Link Direction] = "FALSE"
      Opts.Global.[Network Options].[Time Unit] = "Minutes"
      Opts.Global.[Length Unit] = "Miles"
    
      if pk_hour then Opts.Global.[Link Options] = {{"Time", {llayer + ".AB_Time_PK", llayer + ".BA_Time_PK", , , "True"}}}
      if !pk_hour then Opts.Global.[Link Options] = {{"Time", {llayer + ".AB_Time_OP", llayer + ".BA_Time_OP", , , "True"}}}
	  
	    if pk_hour then Opts.Global.[Link Options] = Opts.Global.[Link Options] + {{"FFTime", {llayer + ".ABFF_Time_PK", llayer + ".BAFF_Time_PK", , , "True"}}}
	    if !pk_hour then Opts.Global.[Link Options] = Opts.Global.[Link Options] + {{"FFTime", {llayer + ".ABFF_Time_OP", llayer + ".BAFF_Time_OP", , , "True"}}}
      
      Opts.Global.[Link Options] = Opts.Global.[Link Options] + {{"Length", {llayer + ".Length", llayer + ".Length", , , "False"}},
      {"[AB_Cap / BA_Cap]", {llayer + ".AB_Cap", llayer + ".BA_Cap", , , "False"}},
      {"Preload", {llayer + ".Preload", llayer + ".Preload", , , "False"}},
      {"ALPHA_", {llayer + ".ALPHA_", llayer + ".ALPHA_", , , "False"}},
      {"BETA_", {llayer + ".BETA_", llayer + ".BETA_", , , "False"}}}
      
      Opts.Output.[Network File] = network_file
      
      ret_value = RunMacro("TCB Run Operation", 1, "Build Highway Network", Opts)
      if !ret_value then goto quit
    
      // Highway Network Setting
      Opts = null
      Opts.Input.Database = highway_layer
      Opts.Input.Network = network_file
      Opts.Input.[Centroids Set] = {db_nodelyr, nlayer, "centroids", "Select * where Centroid = 1"}            
      ret_value = RunMacro("TCB Run Operation", 2, "Highway Network Setting", Opts)
      if !ret_value then goto quit
      
      // Skim Network
      Opts = null
      Opts.Input.Network = network_file
      Opts.Input.[Origin Set] = {db_nodelyr, nlayer, "centroids", "Select * where Centroid = 1"}
      Opts.Input.[Destination Set] = {db_nodelyr, nlayer, "centroids"}
      Opts.Input.[Via Set] = {db_nodelyr, nlayer}
      Opts.Field.Minimize = "Time"
      Opts.Field.Nodes = "["+nlayer+"].ID"
      Opts.Field.[Skim Fields] = {{"Length", "All"}}
      Opts.Output.[Output Matrix].Label = "SPMAT " + String(hour)
      Opts.Output.[Output Matrix].[File Name] = skim_mat
      ret_value = RunMacro("TCB Run Procedure", 13, "TCSPMAT", Opts)   
      
      RunMacro("Close All")
    end     // end of hour
    
    if convert_skims_to_csv then RunMacro("ConvertSkimsToCSV", model_dir, skims_dir) 

    RunMacro("RunPOEChoiceModel", model_dir, source_dir, r_program_path, property_file)
    
    RunMacro("CreateTripMatrices", model_dir, assignment_dir, do_ome)
   
    ret_value = RunMacro("RunTranscadAssignment", model_dir, skims_dir, assignment_dir, highway_layer, do_ome)   
    if !ret_value then goto quit

    if iteration >= max_iter then converged = 1
    
    RunMacro("CopyOutputs", model_dir, source_dir, iteration) 
    
  end         // end of convergence loop
	
	quit:
	RunMacro("Close All")
	Return(RunMacro("TCB Closing", ret_value, True))
EndMacro

Macro "ConvertTripsToCSV" (model_dir, trips_dir)
  // export trips to csv
  for hour = 1 to 24 do
  	matrix_file = model_dir + trips_dir + "Trips_" + String(hour) + ".mtx"
  	csv_file = model_dir + trips_dir + "Trips_" + String(hour) + ".csv"
  	
  	mat = OpenMatrix(matrix_file, )
  	mat_cores = GetMatrixCoreNames(mat)
    CreateTableFromMatrix(mat, csv_file, "CSV", {{"Complete", "No"}, {"Tables", mat_cores}})
    mat = null
    
    rds_file = model_dir + trips_dir + "Trips_" + String(hour) + ".RDS"
    if(GetFileInfo(rds_file) <> null) then DeleteFile(rds_file)
  end
EndMacro
  
Macro "ConvertSkimsToCSV" (model_dir, skims_dir)
  // export skims to csv
  for hour = 1 to 24 do
  	matrix_file = model_dir + skims_dir + "Skims_" + String(hour) + ".mtx"
  	csv_file = model_dir + skims_dir + "Skims_" + String(hour) + ".csv"
  	
  	mat = OpenMatrix(matrix_file, )
  	mat_cores = GetMatrixCoreNames(mat)
    CreateTableFromMatrix(mat, csv_file, "CSV", {{"Complete", "No"}, {"Tables", mat_cores}})
    mat = null
    
    rds_file = model_dir + skims_dir + "Skims_" + String(hour) + ".RDS"
    if(GetFileInfo(rds_file) <> null) then DeleteFile(rds_file)
  end
EndMacro

Macro "CreateTripMatrices" (model_dir, assignment_dir, do_ome) 
  cores_list = {"POV_GP_SY", "POV_RE_SY", "POV_SE_SY", "POV_GP_OM", "POV_RE_OM", "POV_SE_OM", "COM_GP_OM", "COM_SP_OM"}
  if(do_ome) then cores_list = cores_list + {"POV_GP_OME", "POV_RE_OME", "POV_SE_OME", "COM_GP_OME", "COM_SP_OME"}

  csv_file = model_dir + assignment_dir + "poe_model_trips.csv"
  csv_file = Substitute(csv_file, "/", "\\", )
  For hour = 1 to 24 do
		mtx_file = model_dir + assignment_dir + "Trips_" + String(hour) + ".mtx"
		mat = CreateMatrixFromScratch("POE Trips", 5315, 5315, {{"File Name", mtx_file}, {"Label","Trips"}, {"Type","Float"}, {"Tables",cores_list}, {"Compression",True}})
		
		For i = 1 to ArrayLength(cores_list) do
	    //Open the trip table for conversion to matrix format
		  table_vw = OpenTable("Data", "CSV", {csv_file, null})
		  SetView(table_vw)
		  query = "Select * where core = '" + cores_list[i] + "' and hour = " + String(hour)
	    n_sel = SelectByQuery("Selection", "Several", query, )
	    
	    matrix_name = cores_list[i]
	    
	    mc = CreateMatrixCurrency(mat, matrix_name, "Row Index", "Column Index",)
			table_set = table_vw + "|Selection"
			rec = GetFirstRecord(table_set, null)
			while rec <> null do
				old_value = GetMatrixValue(mc, string(table_vw.orig), string(table_vw.dest))
				if (old_value = null) then old_value = 0
				
				new_value = old_value + table_vw.trips
								
				SetMatrixValue(mc, string(table_vw.orig), string(table_vw.dest), new_value)
				rec = GetNextRecord(table_set, null, null)
			end

			CloseView(table_vw)
			mc = null
		end

    mat = null
			
	end
	
EndMacro

Macro "RunTranscadAssignment" (model_dir, skims_dir, assignment_dir, highway_layer, do_ome)  
  map = RunMacro("G30 new map", highway_layer, "False")
  layers = GetDBlayers(highway_layer)
  nlayer = layers[1]
  llayer = layers[2]
  db_nodelyr = highway_layer + "|" + nlayer
  db_linklyr = highway_layer + "|" + llayer
  SetLayer(llayer)
   
  // OD MATRIX Cores - 8 or 13
  // POV_GP_SY, POV_RE_SY, POV_SE_SY, POV_GP_OM, POV_RE_OM, POV_SE_OM, COM_GP_OM, COM_SP_OM
  // POV_GP_OME, POV_RE_OME, POV_SE_OME, COM_GP_OME, COM_SP_OME

  POV_GP_SY = {db_linklyr, "binational", "POV_GP_SY", "Select * where POE='OM' or POE='OME' or POE_Lane='POV_RE' or POE_Lane='POV_SE'"}
  POV_RE_SY = {db_linklyr, "binational", "POV_RE_SY", "Select * where POE='OM' or POE='OME' or POE_Lane='POV_GP' or POE_Lane='POV_SE'"}
  POV_SE_SY = {db_linklyr, "binational", "POV_SE_SY", "Select * where POE='OM' or POE='OME' or POE_Lane='POV_GP' or POE_Lane='POV_RE'"}
  
  POV_GP_OM = {db_linklyr, "binational", "POV_GP_OM", "Select * where POE='SY' or POE='OME' or POE_Lane='POV_RE' or POE_Lane='POV_SE' or POE_Lane='COM_GP' or POE_Lane='COM_SP' or POE_Lane='COM_SB'"}
  POV_RE_OM = {db_linklyr, "binational", "POV_RE_OM", "Select * where POE='SY' or POE='OME' or POE_Lane='POV_GP' or POE_Lane='POV_SE' or POE_Lane='COM_GP' or POE_Lane='COM_SP' or POE_Lane='COM_SB'"}
  POV_SE_OM = {db_linklyr, "binational", "POV_SE_OM", "Select * where POE='SY' or POE='OME' or POE_Lane='POV_GP' or POE_Lane='POV_RE' or POE_Lane='COM_GP' or POE_Lane='COM_SP' or POE_Lane='COM_SB'"}
  
  POV_GP_OME = {db_linklyr, "binational", "POV_GP_OME", "Select * where POE='SY' or POE='OM' or POE_Lane='POV_RE' or POE_Lane='POV_SE' or POE_Lane='COM_GP' or POE_Lane='COM_SP' or POE_Lane='COM_SB'"}
  POV_RE_OME = {db_linklyr, "binational", "POV_RE_OME", "Select * where POE='SY' or POE='OM' or POE_Lane='POV_GP' or POE_Lane='POV_SE' or POE_Lane='COM_GP' or POE_Lane='COM_SP' or POE_Lane='COM_SB'"}
  POV_SE_OME = {db_linklyr, "binational", "POV_SE_OME", "Select * where POE='SY' or POE='OM' or POE_Lane='POV_GP' or POE_Lane='POV_RE' or POE_Lane='COM_GP' or POE_Lane='COM_SP' or POE_Lane='COM_SB'"}
  
  COM_GP_OM = {db_linklyr, "binational", "COM_GP_OM", "Select * where POE='SY' or POE='OME' or POE_Lane='POV_GP' or POE_Lane='POV_RE' or POE_Lane='POV_SE' or POE_Lane='COM_SP'"}
  COM_SP_OM = {db_linklyr, "binational", "COM_SP_OM", "Select * where POE='SY' or POE='OME' or POE_Lane='POV_GP' or POE_Lane='POV_RE' or POE_Lane='POV_SE' or POE_Lane='COM_GP'"}
  
  COM_GP_OME = {db_linklyr, "binational", "COM_GP_OME", "Select * where POE='SY' or POE='OM' or POE_Lane='POV_GP' or POE_Lane='POV_RE' or POE_Lane='POV_SE' or POE_Lane='COM_SP'"}
  COM_SP_OME = {db_linklyr, "binational", "COM_SP_OME", "Select * where POE='SY' or POE='OM' or POE_Lane='POV_GP' or POE_Lane='POV_RE' or POE_Lane='POV_SE' or POE_Lane='COM_GP'"}

  For hour = 1 to 24 do 
    od_matrix = model_dir + assignment_dir + "Trips_" + string(hour) + ".mtx"
    od_matrix = Substitute(od_matrix, "/", "\\", )
    
    assignment_table = model_dir + assignment_dir + "assign_" + string(hour) + ".bin"
    assignment_table = Substitute(assignment_table, "/", "\\", )
    
    network_file = model_dir + skims_dir + "network_" + string(hour) + ".net"
    network_file = Substitute(network_file, "/", "\\", )
   
    // Highway Assignment - MMA
	  Opts = null
	  Opts.Input.Database = highway_layer
	  Opts.Input.Network = network_file
	  Opts.Input.[OD Matrix Currency] = {od_matrix, "POV_GP_SY", "Row index", "Column index"}
	  Opts.Field.[VDF Fld Names] = {"FFTime", "[AB_CAP / BA_CAP]", "ALPHA_", "BETA_", "Preload"}
	  Opts.Global.[Load Method] = "NCFW"
	  Opts.Global.[N Conjugate] = 2
	  Opts.Global.[Loading Multiplier] = 1
	  Opts.Global.Convergence = 0.001
	  Opts.Global.Iterations = 15
	  
	  if(do_ome) then do 
	    Opts.Input.[Exclusion Link Sets] = {POV_GP_SY, POV_RE_SY, POV_SE_SY, POV_GP_OM, POV_RE_OM, POV_SE_OM, COM_GP_OM, COM_SP_OM, POV_GP_OME, POV_RE_OME, POV_SE_OME, COM_GP_OME, COM_SP_OME}
	    Opts.Field.[Vehicle Classes] = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13}
	    Opts.Field.[PCE Fields] = {"None", "None", "None", "None", "None", "None", "None", "None", "None", "None", "None", "None", "None"}
	    Opts.Global.[Number of Classes] = 13
	    Opts.Global.[Class PCEs] = {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1}
	  end
	  else do 
      Opts.Input.[Exclusion Link Sets] = {POV_GP_SY, POV_RE_SY, POV_SE_SY, POV_GP_OM, POV_RE_OM, POV_SE_OM, COM_GP_OM, COM_SP_OM}
	    Opts.Field.[Vehicle Classes] = {1, 2, 3, 4, 5, 6, 7, 8}
	    Opts.Field.[PCE Fields] = {"None", "None", "None", "None", "None", "None", "None", "None"}
	    Opts.Global.[Number of Classes] = 8
	    Opts.Global.[Class PCEs] = {1, 1, 1, 1, 1, 1, 1, 1}
	  end
	  
	  Opts.Global.[Cost Function File] = "bpr.vdf"
	  Opts.Global.[VDF Defaults] = {, , 0.15, 4, 0}
	  Opts.Output.[Flow Table] = assignment_table
	  
	  ret_value = RunMacro("TCB Run Procedure", "MMA", Opts, &Ret)
	  if !ret_value then goto quit
	end           // end of hour loop for assignment
	return(1)
	quit:
	RunMacro("Close All")
	return(0)
EndMacro

Macro "RunPOEChoiceModel" (model_dir, source_dir, r_program_path, property_file)
  batch_file = source_dir + "run.bat"
  RunMacro("CreateBatchFile", batch_file, model_dir, r_program_path, property_file)
  RunProgram(batch_file, {{"Minimize", "True"}})
EndMacro

Macro "CreateBatchFile" (batch_file, model_dir, r_program_path, property_file)
    f = OpenFile(batch_file,"w")
    
    model_dir = Substitute(model_dir, "\\", "/", )
    property_file = Substitute(property_file, "\\", "/", )
    r_program_path = Substitute(r_program_path, "\\", "/", )
    
  //line = "@ECHO off"
    line = "@ECHO on"
    WriteLine(f, line)
    
    WriteLine(f, "") 
    
    line = 'SET rPath=' + '"' + r_program_path + '"'
    WriteLine(f, line)
    
    WriteLine(f, "") 
    
    line = 'SET modelPath=' + '"' + model_dir + '"'
    WriteLine(f, line)
    
    WriteLine(f, "") 
    
    line = 'title Run simulations 1 to 50'
    WriteLine(f, line)
    line = '%rPath%Rscript.exe %modelPath%model/allocate_demand_to_ports_of_entry.R ' + property_file + " 1 50"
    WriteLine(f, line)
    
    line = 'title Run simulations 51 to 100'
    WriteLine(f, line)
    line = '%rPath%Rscript.exe %modelPath%model/allocate_demand_to_ports_of_entry.R ' + property_file + " 51 100"
    WriteLine(f, line)
    
    line = 'title Run simulations 101 to 150'
    WriteLine(f, line)    
    line = '%rPath%Rscript.exe %modelPath%model/allocate_demand_to_ports_of_entry.R ' + property_file + " 101 150"
    WriteLine(f, line)

    line = 'title Run simulations 151 to 200'
    WriteLine(f, line)    
    line = '%rPath%Rscript.exe %modelPath%model/allocate_demand_to_ports_of_entry.R ' + property_file + " 151 200"
    WriteLine(f, line)

    line = 'title Run simulations 201 to 250'
    WriteLine(f, line)     
    line = '%rPath%Rscript.exe %modelPath%model/allocate_demand_to_ports_of_entry.R ' + property_file + " 201 250"
    WriteLine(f, line)

    line = 'title Run simulations 251 to 300'
    WriteLine(f, line)    
    line = '%rPath%Rscript.exe %modelPath%model/allocate_demand_to_ports_of_entry.R ' + property_file + " 251 300"
    WriteLine(f, line)
    
    line = 'title Run simulations 301 to 350'
    WriteLine(f, line)     
    line = '%rPath%Rscript.exe %modelPath%model/allocate_demand_to_ports_of_entry.R ' + property_file + " 301 350"
    WriteLine(f, line)

    line = 'title Run simulations 351 to 400'
    WriteLine(f, line)    
    line = '%rPath%Rscript.exe %modelPath%model/allocate_demand_to_ports_of_entry.R ' + property_file + " 351 400"
    WriteLine(f, line)
    
    CloseFile(f)
EndMacro

Macro "Close All"
  // Close maps
  maps = GetMapNames()
  if maps <> null then do
    for i = 1 to maps.length do
      CloseMap(maps[i])
    end
  end

  // Close any views
  RunMacro("TCB Init")
  RunMacro("G30 File Close All")

  // Close matrices
  mtxs = GetMatrices()
  if mtxs <> null then do
    handles = mtxs[1]
    for i = 1 to handles.length do
      handles[i] = null
    end
  end
EndMacro

Macro "ReadProperty" (file, key, ctype)
  //ctype as "s" for character type, "i" for integer
  //macro only reads integers and strings
  //reads property as string and returns either an integer or a string

 	info = GetFileInfo(file)
	fptr = OpenFile(file,"r")
                                               
	//search key in properties file                       
  all_properties = ReadArray(fptr)                                           
  for p = 1 to all_properties.length do   
    // search for the key (line number is stored as k value)                                   
    pos1 = position(all_properties[p],key)                              
    if pos1 = 1 then do 
     // gets the value on the right side of "=" 
      keyword = ParseString(all_properties[p], "=")
      keyvaltrim = trim(keyword[2])
       if ctype = "i" then do  // integer
        keyval = S2I(keyvaltrim)
      end
      else do  // if not i then it's a string
        keyval = keyvaltrim   // gets the string on the rightside of "=" 
      end
    end                                                   
  end 
  CloseFile(fptr)  
  Return(keyval)
EndMacro

Macro "GetDirectory"
    notfound = "True"
    while notfound do
        dir = ChooseDirectory("Select the SR11 OME Model directory",)
        a = GetDirectoryInfo(dir + "\\model","All")
        b = GetDirectoryInfo(dir + "\\data_in","All")
        if a = null then do
            ShowMessage("Incorrect installation directory, try again")
        end
        else if b = null then do
            ShowMessage("Incorrect installation directory, try again")
        end
        else do
            notfound = "False"
        end
    end
    return(dir)
EndMacro

Macro "AddFields" (layer, field_names, field_types)
    fd = field_names.length
		dim fldtypes[fd]
		
		for i = 1 to field_names.length do
			if field_types[i] = "r" then fldtypes[i] = {"Real", 12, 2}
			if field_types[i] = "i" then fldtypes[i] = {"Integer", 10, 3}
			if field_types[i] = "c" then fldtypes[i] = {"String", 16, null}
		end
		
		struct = GetTableStructure(layer)
		dim snames[1]
  	for i = 1 to struct.length do
  		struct[i] = struct[i] + {struct[i][1]}
  		snames = snames + {struct[i][1]}
		end
		
  	modtab = 0
  	for i = 1 to field_names.length do
  	   pos = ArrayPosition(snames, {field_names[i]}, )
  	   if pos = 0 then do
  	      newstr = newstr + {{field_names[i], fldtypes[i][1], fldtypes[i][2], fldtypes[i][3], 
  	                 "false", null, null, null, null}}
  	      modtab = 1
  	   end
  	end
  	
  	if modtab = 1 then do
  		newstr = struct + newstr
  		ModifyTable(layer, newstr)
  	end
EndMacro

Macro "CopyOutputs" (model_dir, source_dir, iteration) 
  model_dir = Substitute(model_dir, "/", "\\", )
  source_dir = Substitute(source_dir, "/", "\\", )
  
  batch_file = source_dir + "copyfiles.bat"
  output_dir = model_dir + "data_out"
  
  LaunchProgram(batch_file + " " + output_dir + " " + String(iteration))
EndMacro
