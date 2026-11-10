library(jsonlite)
library(httr2)
library(readr)
library(digest)
library(dplyr)
source('R/utils_rejouer_api.R')
source('datasets/niveaux-eau-inondation/preparation-api.R')
rejouer_api('niveaux-eau-inondation', '9433786e-5bed-4bc3-a9b9-f9efae4a6b77',
  'datasets/niveaux-eau-inondation/snapshots/20261110T152955Z/source-api.zip',
  preparer_niveaux_api, 'DB_NIVEAUX_SNAPSHOT')
