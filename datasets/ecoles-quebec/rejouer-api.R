library(jsonlite)
library(httr2)
library(readr)
library(digest)
library(dplyr)
source('R/utils_rejouer_api.R')
source('datasets/ecoles-quebec/preparation-api.R')
rejouer_api('ecoles-quebec', 'c6640a54-bc4b-43ec-864e-6c325dce61bc',
  'datasets/ecoles-quebec/snapshots/20261110T151326Z/source-api.zip',
  preparer_ecoles_api, 'DB_ECOLES_SNAPSHOT')
