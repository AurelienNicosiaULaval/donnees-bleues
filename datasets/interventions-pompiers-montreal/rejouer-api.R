# Reconstruire les activités depuis la copie datée de l’API.
library(jsonlite)
library(httr2)
library(readr)
library(digest)
library(dplyr)
library(lubridate)
source('R/utils_rejouer_api.R')
source('datasets/interventions-pompiers-montreal/preparation-api.R')
rejouer_api('interventions-pompiers-montreal', '71e86320-e35c-4b4c-878a-e52124294355',
  'datasets/interventions-pompiers-montreal/snapshots/20261110T200055Z/source-api.zip',
  preparer_pompiers_api, 'DB_POMPIERS_SNAPSHOT')
