options(stringsAsFactors = FALSE)

shinyServer(function(input, output, session) {
  observe({
    shinyjs::hide("action")
    
    if(locationSpecified() == 1)
      shinyjs::show("action")
    
  })
  
  observeEvent(
    ignoreNULL = TRUE,
    eventExpr = {
      input$inputDir
    },
    handlerExpr = {
      if (input$inputDir > 0) {
        # condition prevents handler execution on initial app launch
        
        # launch the directory selection dialog with initial path read from the widget
        path = choose.dir(default = readDirectoryInput(session, 'inputDir'))
        #path = "C:/Projects/SANDAG/Otay_Mesa/sr11_ome_v2/data_out"
        # update the widget value
        updateDirectoryInput(session, 'inputDir', value = path)
      }
    }
  )
  
  input_location <- renderText({
    readDirectoryInput(session, 'inputDir')
  })
  
  max_iter <- renderText({
    input$maxIter
  })
  
  start_hour <- reactive({
    input$startHour
  })
  
  end_hour <- reactive({
    input$endHour
  })
  
  locationSpecified <- renderText(
    if(input_location() != "" & input_location() != " ")
      return(1)
    else 
      return(0)
  )
  
  output$mainTabs <- renderUI({
    if(locationSpecified() == 1){
      tabsetPanel(id = "mainTabs",
                  tabPanel("Volumes", value = 1, br(),
                           plotlyOutput("GPVolPlot", width = "1200px", height = "600px"), br(),
                           plotlyOutput("REVolPlot", width = "1200px", height = "600px"), br(),
                           plotlyOutput("SEVolPlot", width = "1200px", height = "600px"), br()
                  ),
                  tabPanel("Open Lanes", value = 2, br(),
                           div(style="display: inline-block;vertical-align:top;",
                               selectInput("startHour", label = "Start Hour", choices = c(1:24), selected = 1, width = 100)),
                           div(style="display: inline-block;vertical-align:top; width: 25px;",HTML("<br>")),
                           div(style="display: inline-block;vertical-align:top;",
                               selectInput("endHour", label = "End Hour", choices = c(1:24), selected = 6, width = 100)),
                           br(),
                           plotOutput("SYLanePlot"), br(),
                           plotOutput("OMLanePlot"), br(),
                           plotOutput("OMELanePlot")
                  )
      )
    }
  })
  
  input_data <- reactive({
    input$action
    isolate({
      if(input_location() == "" | input_location() == " ")
        return(NULL)
      read_data(input_location(), max_iter())
    })
  })
  
  values <- reactiveValues()
  
  observe({
    if (!is.null(input_data())){
      values[['volumePlots']] <- getVolumePlots(input_data())    
      values[['lanePlots']] <- getLanePlots(input_data(), start_hour(), end_hour())
    }
  })
  
  output$GPVolPlot <- renderPlotly({
    if(is.null(values[['volumePlots']][[1]]))
       return(NULL)
    values[['volumePlots']][[1]]
  })
  
  output$REVolPlot <- renderPlotly({
    if(is.null(values[['volumePlots']][[2]]))
      return(NULL)
    values[['volumePlots']][[2]]
    
  })
  
  output$SEVolPlot <- renderPlotly({
    if(is.null(values[['volumePlots']][[3]]))
      return(NULL)
    values[['volumePlots']][[3]]
    
  })
  
  output$SYLanePlot <- renderPlot({
    values[['lanePlots']][[1]]
  })
  
  output$OMLanePlot <- renderPlot({
    values[['lanePlots']][[2]]
  })
  
  output$OMELanePlot <- renderPlot({
    values[['lanePlots']][[3]]
  })
})
    