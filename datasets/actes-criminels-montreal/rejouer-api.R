library(jsonlite)
library(httr2)
library(readr)
library(digest)
library(dplyr)
source('R/utils_rejouer_api.R')
source('datasets/actes-criminels-montreal/preparation-api.R')
rejouer_api('actes-criminels-montreal', 'c6f482bf-bf0f-4960-8b2f-9982c211addd',
  'datasets/actes-criminels-montreal/snapshots/20261110T152208Z/source-api.zip',
  preparer_actes_api, 'DB_ACTES_SNAPSHOT')
