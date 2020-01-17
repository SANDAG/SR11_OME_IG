args=commandArgs(trailingOnly=TRUE)
folder_address = args[1]

if(!"shiny" %in% installed.packages()) install.packages("shiny", repos = "https://cran.cnr.berkeley.edu/")
if(!"shinydashboard" %in% installed.packages()) install.packages("shinydashboard", repos = "https://cran.cnr.berkeley.edu/")

suppressWarnings(suppressMessages(require(shiny)))
suppressWarnings(suppressMessages(runApp(folder_address, launch.browser=TRUE)))
