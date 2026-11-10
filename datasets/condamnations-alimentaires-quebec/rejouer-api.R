library(jsonlite)
library(httr2)
library(readr)
library(digest)
library(dplyr)
source('R/utils_rejouer_api.R')
source('datasets/condamnations-alimentaires-quebec/preparation-api.R')
rejouer_api('condamnations-alimentaires-quebec', '40105615-3abf-414b-bcba-182e8f2c5eb2',
  'datasets/condamnations-alimentaires-quebec/snapshots/20261110T153456Z/source-api.zip',
  preparer_condamnations_api, 'DB_CONDAMNATIONS_SNAPSHOT')
