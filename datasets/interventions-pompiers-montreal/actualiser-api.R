# Acquérir les cinq champs des activités, sans les coordonnées ni les identifiants.
library(jsonlite)
library(httr2)
library(readr)
library(digest)
library(xml2)
library(dplyr)
library(lubridate)
source('R/utils_downloads.R')
source('R/utils_ckan.R')
source('R/utils_donnees_quebec.R')
source('datasets/interventions-pompiers-montreal/preparation-api.R')
brut <- dq_acquire('interventions-pompiers-montreal', '71e86320-e35c-4b4c-878a-e52124294355',
  fields = c('CREATION_DATE_TIME', 'INCIDENT_TYPE_DESC', 'DESCRIPTION_GROUPE', 'NOM_ARROND', 'NOMBRE_UNITES'))
table <- preparer_pompiers_api(brut)
sortie <- file.path(dirname(brut), 'table-activite.csv')
readr::write_csv(table, sortie, na = 'NA')
jsonlite::write_json(list(fichier_source = basename(brut), sha256_source = digest::digest(file = brut, algo = 'sha256'),
  fichier_prepare = basename(sortie), sha256_prepare = digest::digest(file = sortie, algo = 'sha256'),
  preparation = 'datasets/interventions-pompiers-montreal/preparation-api.R',
  sha256_preparation = digest::digest(file = 'datasets/interventions-pompiers-montreal/preparation-api.R', algo = 'sha256'),
  prepare_utc = format(Sys.time(), '%Y-%m-%dT%H:%M:%SZ', tz = 'UTC'), lignes = nrow(table), colonnes = names(table)),
  file.path(dirname(brut), 'preparation.json'), pretty = TRUE, auto_unbox = TRUE)
Sys.setenv(DB_POMPIERS_SNAPSHOT = sortie)
message('Table préparée : ', sortie, '\nElle sera utilisée dans cette session R.',
  '\nPour la réutiliser dans une nouvelle session :\n',
  'Sys.setenv(DB_POMPIERS_SNAPSHOT = ', encodeString(sortie, quote = '"'), ')')
