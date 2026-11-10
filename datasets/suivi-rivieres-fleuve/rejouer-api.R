library(jsonlite)
library(httr2)
library(readr)
library(digest)
library(dplyr)
source('R/utils_rejouer_api.R')
source('datasets/suivi-rivieres-fleuve/preparation-api.R')
rejouer_api('suivi-rivieres-fleuve', '7e0dfa92-7480-425a-8dab-5eb52a4d9b94',
  'datasets/suivi-rivieres-fleuve/snapshots/20261110T154923Z/source-api.zip',
  preparer_rivieres_api, 'DB_RIVIERES_SNAPSHOT')
