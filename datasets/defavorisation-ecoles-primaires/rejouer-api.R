library(jsonlite)
library(httr2)
library(readr)
library(digest)
library(dplyr)
source('R/utils_rejouer_api.R')
source('datasets/defavorisation-ecoles-primaires/preparation-api.R')
rejouer_api('defavorisation-ecoles-primaires', '6c5d4a5d-ba3b-40a6-b570-916f43ab622c',
  'datasets/defavorisation-ecoles-primaires/snapshots/20261110T153456Z/source-api.zip',
  preparer_defavorisation_api, 'DB_DEFAVORISATION_SNAPSHOT')
