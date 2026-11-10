library(jsonlite)
library(httr2)
library(readr)
library(digest)
library(dplyr)
source('R/utils_rejouer_api.R')
source('datasets/qualite-air-horaire/preparation-api.R')
rejouer_api('qualite-air-horaire', '370a6be4-1530-4c2b-92f3-0a308224f284',
  'datasets/qualite-air-horaire/snapshots/20261110T154506Z/source-api.zip',
  preparer_air_horaire_api, 'DB_AIR_HORAIRE_SNAPSHOT')
