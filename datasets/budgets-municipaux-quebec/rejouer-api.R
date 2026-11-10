library(jsonlite)
library(httr2)
library(readr)
library(digest)
library(dplyr)
source('R/utils_rejouer_api.R')
source('datasets/budgets-municipaux-quebec/preparation-api.R')
rejouer_api('budgets-municipaux-quebec', '15192f34-a635-47f5-aaf9-eb1621d65b2e',
  'datasets/budgets-municipaux-quebec/snapshots/20261110T154129Z/source-api.zip',
  preparer_budgets_api, 'DB_BUDGETS_SNAPSHOT')
