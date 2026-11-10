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
source('datasets/qualite-air-horaire/preparation-api.R')
brut <- dq_acquire('qualite-air-horaire', '370a6be4-1530-4c2b-92f3-0a308224f284',
  fields = c('Station', 'Date_Heure', 'BC_880nm', 'CO', 'H2S', 'NO2-CAPS', 'NO2', 'NO-CAPS', 'NO', 'O3', 'PM0.1-CPC', 'PM2.5-T640', 'SO2'))
table <- preparer_air_horaire_api(brut)
sortie <- file.path(dirname(brut), 'table-activite.csv')
readr::write_csv(table, sortie, na = 'NA')
jsonlite::write_json(list(fichier_source = basename(brut), sha256_source = digest::digest(file = brut, algo = 'sha256'),
  fichier_prepare = basename(sortie), sha256_prepare = digest::digest(file = sortie, algo = 'sha256'),
  preparation = 'datasets/qualite-air-horaire/preparation-api.R',
  sha256_preparation = digest::digest(file = 'datasets/qualite-air-horaire/preparation-api.R', algo = 'sha256'),
  prepare_utc = format(Sys.time(), '%Y-%m-%dT%H:%M:%SZ', tz = 'UTC'),
  lignes = nrow(table), colonnes = names(table)),
  file.path(dirname(brut), 'preparation.json'), pretty = TRUE, auto_unbox = TRUE)
Sys.setenv(DB_AIR_HORAIRE_SNAPSHOT = sortie)
message('Instantané préparé : ', sortie, '\nLes activités utiliseront cette copie dans cette session R.',
  '\nPour la réutiliser dans une nouvelle session :\n',
  'Sys.setenv(DB_AIR_HORAIRE_SNAPSHOT = ', encodeString(sortie, quote = '"'), ')')
