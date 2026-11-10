# Acquérir et préparer un nouvel instantané pour les activités.
library(jsonlite)
library(httr2)
library(readr)
library(digest)
library(xml2)
library(dplyr)
source('R/utils_downloads.R')
source('R/utils_ckan.R')
source('R/utils_donnees_quebec.R')
source('datasets/qualite-air/preparation-api.R')
brut <- dq_acquire('qualite-air', 'cebea532-a9e0-4a39-8c2d-54f33d937c73',
  fields = c('ID_STATION', 'NOM_STATION', 'RA', 'TYPE_MILIEU', 'DATE_OUVERTURE', 'DATE_FERMETURE', 'LATITUDE', 'LONGITUDE'))
table <- preparer_air_api(brut)
sortie <- file.path(dirname(brut), 'table-activite.csv')
readr::write_csv(table, sortie, na = 'NA')
jsonlite::write_json(list(fichier_source = basename(brut), sha256_source = digest::digest(file = brut, algo = 'sha256'),
  fichier_prepare = basename(sortie), sha256_prepare = digest::digest(file = sortie, algo = 'sha256'),
  preparation = 'datasets/qualite-air/preparation-api.R',
  sha256_preparation = digest::digest(file = 'datasets/qualite-air/preparation-api.R', algo = 'sha256'),
  prepare_utc = format(Sys.time(), '%Y-%m-%dT%H:%M:%SZ', tz = 'UTC'),
  lignes = nrow(table), colonnes = names(table)),
  file.path(dirname(brut), 'preparation.json'), pretty = TRUE, auto_unbox = TRUE)
Sys.setenv(DB_AIR_SNAPSHOT = sortie)
message('Instantané préparé : ', sortie, '\nLes activités utiliseront cette copie dans cette session R.',
  '\nPour la réutiliser dans une nouvelle session :\n',
  'Sys.setenv(DB_AIR_SNAPSHOT = ', encodeString(sortie, quote = '"'), ')')
