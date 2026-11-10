library(jsonlite)
library(httr2)
library(readr)
library(digest)
library(dplyr)
source('R/utils_rejouer_api.R')
source('datasets/prelevements-eau-autorises/preparation-api.R')
rejouer_api('prelevements-eau-autorises', '5c090292-a681-4413-9399-f17bcdf62753',
  'datasets/prelevements-eau-autorises/snapshots/20261110T153456Z/source-api.zip',
  preparer_prelevements_api, 'DB_PRELEVEMENTS_SNAPSHOT')
