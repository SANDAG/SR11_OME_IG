source('directoryInput.R')
source('installPackages.R')

library(shiny)
library(shinydashboard)
library(xlsx)
library(readr)
library(dplyr)
library(tidyr)
library(plotly)
library(shinyjs)

header <- dashboardHeader(
  title = "SR11 OME Model Output Summary",
  titleWidth = 350
)

sidebar <- dashboardSidebar(
  width = 350,
  
  tags$hr(),
  directoryInput("inputDir", label = "Select Output Location", value = ""),
  
  useShinyjs(),
  conditionalPanel('input.mainTabs > 0',
                   fluidRow(column(6, numericInput("maxIter", label = "Max Iteration", value = 1, min = 1, width = 200))),
                   fluidRow(column(6, align="center", offset = 3, actionButton("action", "RUN")))
                   
  )
)

body <- dashboardBody(
  uiOutput('mainTabs')
)

dashboardPage(header, sidebar, body)