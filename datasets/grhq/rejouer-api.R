library(jsonlite)
library(httr2)
library(readr)
library(digest)
library(dplyr)
source('R/utils_rejouer_api.R')
source('datasets/grhq/preparation-api.R')
rejouer_api('grhq', '4ef6703f-0ecb-46a0-bdb4-7074f00ff514',
  'datasets/grhq/snapshots/20261110T162735Z/source-api.zip',
  preparer_grhq_api, 'DB_GRHQ_SNAPSHOT')
