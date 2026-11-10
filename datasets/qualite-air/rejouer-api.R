library(jsonlite)
library(httr2)
library(readr)
library(digest)
library(dplyr)
source('R/utils_rejouer_api.R')
source('datasets/qualite-air/preparation-api.R')
rejouer_api('qualite-air', 'cebea532-a9e0-4a39-8c2d-54f33d937c73',
  'datasets/qualite-air/snapshots/20261110T152954Z/source-api.zip',
  preparer_air_api, 'DB_AIR_SNAPSHOT')
