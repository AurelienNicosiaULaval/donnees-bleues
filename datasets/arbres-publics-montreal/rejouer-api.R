library(jsonlite)
library(httr2)
library(readr)
library(digest)
library(dplyr)
source('R/utils_rejouer_api.R')
source('datasets/arbres-publics-montreal/preparation-api.R')
rejouer_api('arbres-publics-montreal', '64e28fe6-ef37-437a-972d-d1d3f1f7d891',
  'datasets/arbres-publics-montreal/snapshots/20261110T153551Z/source-api.zip',
  preparer_arbres_api, 'DB_ARBRES_SNAPSHOT')
