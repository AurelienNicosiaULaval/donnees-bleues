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
source('datasets/suivi-rivieres-fleuve/preparation-api.R')
brut <- dq_acquire('suivi-rivieres-fleuve', '7e0dfa92-7480-425a-8dab-5eb52a4d9b94',
  fields = c('NO_BQMA', 'HYDRONYME', 'ANNEE', 'PTOT_MED_MGL', 'LATITUDE', 'LONGITUDE', 'BV_N1M'))
table <- preparer_rivieres_api(brut)
sortie <- file.path(dirname(brut), 'table-activite.csv')
readr::write_csv(table, sortie, na = 'NA')
jsonlite::write_json(list(fichier_source = basename(brut), sha256_source = digest::digest(file = brut, algo = 'sha256'),
  fichier_prepare = basename(sortie), sha256_prepare = digest::digest(file = sortie, algo = 'sha256'),
  preparation = 'datasets/suivi-rivieres-fleuve/preparation-api.R',
  sha256_preparation = digest::digest(file = 'datasets/suivi-rivieres-fleuve/preparation-api.R', algo = 'sha256'),
  prepare_utc = format(Sys.time(), '%Y-%m-%dT%H:%M:%SZ', tz = 'UTC'),
  lignes = nrow(table), colonnes = names(table)),
  file.path(dirname(brut), 'preparation.json'), pretty = TRUE, auto_unbox = TRUE)
Sys.setenv(DB_RIVIERES_SNAPSHOT = sortie)
message('Instantané préparé : ', sortie, '\nLes activités utiliseront cette copie dans cette session R.',
  '\nPour la réutiliser dans une nouvelle session :\n',
  'Sys.setenv(DB_RIVIERES_SNAPSHOT = ', encodeString(sortie, quote = '"'), ')')
