## Define global functions for the app in this file

# function to get today's date 
getDate <- function(){
  date <- as.Date(Sys.Date())
  date
}

read_data <- function(path, maxIters){
  iters <- c(1:maxIters)
  
  lane_type <- c("POV_GP_SY","POV_RE_SY","POV_SE_SY","POV_SB_SY",
                 "POV_GP_OM","POV_RE_OM","POV_SE_OM","POV_SB_OM","COM_GP_OM","COM_SP_OM","COM_SB_OM")
  
  for(i in iters) {
    results_file <- paste(path, paste0("results_", i, ".xlsx"), sep = "/")
    if(file.exists(results_file)) file.remove(results_file)
    
    file_name <- paste(path, paste0("poe_output_", i, ".csv"), sep = "/")
    if(file.exists(file_name)){
      model_outputs <- read.csv(file_name)
      
      if("OME" %in% unique(model_outputs$POE)){
        lane_type <- c("POV_GP_SY","POV_RE_SY","POV_SE_SY","POV_SB_SY",
                       "POV_GP_OM","POV_RE_OM","POV_SE_OM","POV_SB_OM","COM_GP_OM","COM_SP_OM","COM_SB_OM",
                       "POV_GP_OME","POV_RE_OME","POV_SE_OME","POV_SB_OME","COM_GP_OME","COM_SP_OME","COM_SB_OME")
      }
      
      model_outputs$POE <- trimws(model_outputs$POE)
      model_outputs$Lane <- trimws(model_outputs$Lane)
      
      model_outputs <- model_outputs %>% mutate(Type = factor(paste(Lane, POE, sep = "_"), levels = lane_type))
      model_outputs <- model_outputs %>% mutate(iteration = i)
      
      # open lanes
      open_lanes <- model_outputs %>% select(Hour, Type, Open)
      open_lanes[is.na(open_lanes)] <- 0
      open_lanes <- open_lanes %>% spread(key = Type, value = Open)
      write.xlsx(open_lanes, results_file, sheetName="open_lanes", col.names=TRUE, row.names=FALSE, append=TRUE)
      
      # period vol
      period_vol <- model_outputs %>% select(Hour, Type, Volume)
      period_vol[is.na(period_vol)] <- 0 
      period_vol <- period_vol %>% mutate(Volume = as.integer(Volume))
      period_vol <- period_vol %>% spread(key = Type, value = Volume)
      write.xlsx(period_vol, results_file, sheetName="period_volume", col.names=TRUE, row.names=FALSE, append=TRUE)
      
      # wait time
      wait_time <- model_outputs %>% select(Hour, Type, Wait_Time)
      wait_time[is.na(wait_time)] <- 0 
      wait_time <- wait_time %>% spread(key = Type, value = Wait_Time)
      write.xlsx(wait_time, results_file, sheetName="wait_time", col.names=TRUE, row.names=FALSE, append=TRUE)
      
      # queue
      queue <- model_outputs %>% select(Hour, Type, Queue)
      queue[is.na(queue)] <- 0 
      queue <- queue %>% spread(key = Type, value = Queue)
      write.xlsx(queue, results_file, sheetName="queue", col.names=TRUE, row.names=FALSE, append=TRUE)
      
      #toll
      toll <- model_outputs %>% filter(POE == "OME", Lane == "POV_GP") %>% select(Hour, NB_POV_Toll, NB_Trk_Toll, SB_POV_Toll, SB_Trk_Toll)
      toll[is.na(toll)] <- 0
      names(toll) <- c("Hour", "NB_POV", "NB_COV", "SB_POV", "SB_COV")
      write.xlsx(toll, results_file, sheetName="tolls", col.names=TRUE, row.names=FALSE, append=TRUE)
    }
    
    if(i == 1){
      data <- model_outputs
    } else {
      data <- rbind(data, model_outputs)
    }
  }
  return(data)
}

getVolumePlots <- function(data){
  #data <- read_data(path = "C:/Projects/SANDAG/Otay_Mesa/sr11_ome_v2/data_out", 30)
  
  vol_data <- data %>% select(Hour, POE, Lane, iteration, Volume) %>% group_by(iteration, Lane, POE) %>% summarize(Volume = sum(Volume))
  vol_data <- vol_data %>% filter(Lane %in% c("POV_GP", "POV_RE", "POV_SE"))
  vol_data <- data.frame(vol_data)
  
  ome_present <- 0
  if("OME" %in% unique(vol_data$POE)) ome_present <- 1
  
  gp_vol <- vol_data %>% filter(Lane == "POV_GP") %>% select(iteration, POE, Volume)
  gp_vol <- gp_vol %>% spread(key = POE, value = Volume)
  gp_vol <- data.frame(gp_vol)
  
  re_vol <- vol_data %>% filter(Lane == "POV_RE") %>% select(iteration, POE, Volume)
  re_vol <- re_vol %>% spread(key = POE, value = Volume)
  re_vol <- data.frame(re_vol)
  
  se_vol <- vol_data %>% filter(Lane == "POV_SE") %>% select(iteration, POE, Volume)
  se_vol <- se_vol %>% spread(key = POE, value = Volume)
  se_vol <- data.frame(se_vol)
  
  P1 <- ggplot()
  P1 <- P1 + geom_line(aes(x=iteration, y=SY, color="SY"), gp_vol, size=0.75) 
  P1 <- P1 + geom_point(aes(x=iteration, y=SY), gp_vol, colour="steelblue3", size = 3)
  P1 <- P1 + geom_line(aes(x=iteration, y=OM, color="OM"), gp_vol,  size=0.75)
  P1 <- P1 + geom_point(aes(x=iteration, y=OM), gp_vol, colour="tan2", size = 3)
  
  if(ome_present){
    P1 <- P1 + geom_line(aes(x=iteration, y=OME, color="OME"), gp_vol,  size=0.75)
    P1 <- P1 + geom_point(aes(x=iteration, y=OME), gp_vol, colour="springgreen3", size = 3)
  }

  P1 <- P1 + scale_color_manual("", values=c("SY"="steelblue3", "OM"="tan2", "OME"="springgreen3"))
  P1 <- P1 + labs(y='Daily Volume', x='Iteration', title="GP Volume")
  P1 <- P1 + scale_x_continuous(breaks=c(1:max(gp_vol$iteration))) + scale_y_continuous(labels = scales::comma)
  P1 <- P1 + theme_new()
  P1 <- ggplotly(P1)
  
  P2 <- ggplot()
  P2 <- P2 + geom_line(aes(x=iteration, y=SY, color="SY"), re_vol, size=0.75) 
  P2 <- P2 + geom_point(aes(x=iteration, y=SY), re_vol, colour="steelblue3", size = 3)
  P2 <- P2 + geom_line(aes(x=iteration, y=OM, color="OM"), re_vol,  size=0.75)
  P2 <- P2 + geom_point(aes(x=iteration, y=OM), re_vol, colour="tan2", size = 3)
  
  if(ome_present){
    P2 <- P2 + geom_line(aes(x=iteration, y=OME, color="OME"), re_vol,  size=0.75)
    P2 <- P2 + geom_point(aes(x=iteration, y=OME), re_vol, colour="springgreen3", size = 3)
  }
  
  P2 <- P2 + scale_color_manual("", values=c("SY"="steelblue3", "OM"="tan2", "OME"="springgreen3"))
  
  P2 <- P2 + labs(y='Daily Volume', x='Iteration', title="RE Volume")
  P2 <- P2 + scale_x_continuous(breaks=c(1:max(re_vol$iteration))) + scale_y_continuous(labels = scales::comma)
  P2 <- P2 + theme_new()
  P2 <- ggplotly(P2)
  
  P3 <- ggplot()
  P3 <- P3 + geom_line(aes(x=iteration, y=SY, color="SY"), se_vol, size=0.75) 
  P3 <- P3 + geom_point(aes(x=iteration, y=SY), se_vol, colour="steelblue3", size = 3)
  P3 <- P3 + geom_line(aes(x=iteration, y=OM, color="OM"), se_vol,  size=0.75)
  P3 <- P3 + geom_point(aes(x=iteration, y=OM), se_vol, colour="tan2", size = 3)
 
  if(ome_present){
    P3 <- P3 + geom_line(aes(x=iteration, y=OME, color="OME"), se_vol,  size=0.75)
    P3 <- P3 + geom_point(aes(x=iteration, y=OME), se_vol, colour="springgreen3", size = 3)
  }
  
  P3 <- P3 + scale_color_manual("", values=c("SY"="steelblue3", "OM"="tan2", "OME"="springgreen3"))
  
  P3 <- P3 + labs(y='Daily Volume', x='Iteration', title="SE Volume")
  P3 <- P3 + scale_x_continuous(breaks=c(1:max(se_vol$iteration))) + scale_y_continuous(labels = scales::comma)
  P3 <- P3 + theme_new()
  P3 <- ggplotly(P3)
  
  return(list(P1, P2, P3))
}

getLanePlots <- function(data, start_hour, end_hour){
  start_hour <- as.numeric(start_hour)
  end_hour <- as.numeric(end_hour)
  
  lane_data <- data %>% select(Hour, POE, Lane, iteration, Open) %>% filter(Hour >= start_hour) %>% filter(Hour <= end_hour)
  lane_data <- lane_data %>% filter(Lane %in% c("POV_GP", "POV_RE", "POV_SE"))
  
  ome_present <- 0
  if("OME" %in% unique(lane_data$POE)) ome_present <- 1
  
  sy_lane_data <- lane_data %>% filter(POE == "SY")
  om_lane_data <- lane_data %>% filter(POE == "OM")
  ome_lane_data <- lane_data %>% filter(POE == "OME")
  
  P1 <- ggplot(sy_lane_data, aes(x=iteration, y=Open, fill = Lane)) + geom_bar(position = "stack", stat="identity", width = 0.5) + facet_wrap( ~ Hour)
  P1 <- P1 + labs(x='Iteration', title = 'SY OPEN LANES') + scale_x_continuous(breaks=c(1:max(sy_lane_data$iteration)))
  P1 <- P1 + scale_fill_manual(values = c("orangered", "darkgoldenrod1", "springgreen3"))
  P1 <- P1 + theme(axis.text.y = element_blank())
  
  P2 <- ggplot(om_lane_data, aes(x=iteration, y=Open, fill = Lane)) + geom_bar(position = "stack", stat="identity", width = 0.5) + facet_wrap( ~ Hour)
  P2 <- P2 + labs(x='Iteration', title = 'OM OPEN LANES') + scale_x_continuous(breaks=c(1:max(om_lane_data$iteration)))  
  P2 <- P2 + scale_fill_manual(values = c("orangered", "darkgoldenrod1", "springgreen3"))
  P2 <- P2 + theme(axis.text.y = element_blank())
  
  P3 <- NULL
  if(ome_present){
    P3 <- ggplot(ome_lane_data, aes(x=iteration, y=Open, fill = Lane)) + geom_bar(position = "stack", stat="identity", width = 0.5) + facet_wrap( ~ Hour)
    P3 <- P3 + labs(x='Iteration', title = 'OME OPEN LANES') + scale_x_continuous(breaks=c(1:max(ome_lane_data$iteration)))  
    P3 <- P3 + scale_fill_manual(values = c("orangered", "darkgoldenrod1", "springgreen3"))
    P3 <- P3 + theme(axis.text.y = element_blank())
  }
  
  return(list(P1, P2, P3))
}

theme_new <- function(){
  theme(
    title=element_text(size=16, face="bold",hjust = 0.5),
    axis.title=element_text(size=14,face="bold"),
    axis.text = element_text(size=10),
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    panel.background = element_blank(),
    axis.line.x = element_line(color = "black", size = 1),
    axis.line.y = element_line(color = "black", size = 1),
    legend.position = "top",
    legend.text = element_text(size=20),
    plot.margin = margin(10,10,10,10)
  )
}