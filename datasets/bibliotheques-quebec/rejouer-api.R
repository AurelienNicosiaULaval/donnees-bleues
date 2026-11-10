library(jsonlite)
library(httr2)
library(readr)
library(digest)
library(dplyr)
library(stringi)
source('R/utils_rejouer_api.R')
source('datasets/bibliotheques-quebec/preparation-api.R')
rejouer_api('bibliotheques-quebec', '01183d3e-c79c-4d09-915c-f35ffe4dfda8',
  'datasets/bibliotheques-quebec/snapshots/20261110T133457Z/source-api.zip',
  preparer_bibliotheques_api, 'DB_BIBLIOTHEQUES_SNAPSHOT')
