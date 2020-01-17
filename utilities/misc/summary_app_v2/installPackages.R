# Ashish Kulshrestha | kulshresthaa@pbworld.com | Parsons Brinckerhoff
# Last Edited: Feb 5, 2018
# Script to check if requred packages are already installed, if not then install the packages.

packages <- c("shinyjs", "xlsx", "plotly", "readr", "dplyr", "tidyr")

if (length(setdiff(packages, rownames(installed.packages()))) > 0) {
  install.packages(setdiff(packages, rownames(installed.packages())), repos = "https://cran.cnr.berkeley.edu/")  
}