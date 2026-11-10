# Acquérir et préparer un nouvel instantané pour les activités sur les écoles.
library(jsonlite)
library(httr2)
library(readr)
library(digest)
library(xml2)
library(dplyr)
source('R/utils_downloads.R')
source('R/utils_ckan.R')
source('R/utils_donnees_quebec.R')
source('datasets/ecoles-quebec/preparation-api.R')
brut <- dq_acquire('ecoles-quebec', 'c6640a54-bc4b-43ec-864e-6c325dce61bc')
table <- preparer_ecoles_api(brut)
sortie <- file.path(dirname(brut), 'ecoles-activite.csv')
write_csv(table, sortie, na = 'NA')
jsonlite::write_json(list(fichier_source = basename(brut), sha256_source = digest::digest(file = brut, algo = 'sha256'),
  fichier_prepare = basename(sortie), sha256_prepare = digest::digest(file = sortie, algo = 'sha256'),
  preparation = 'datasets/ecoles-quebec/preparation-api.R',
  sha256_preparation = digest::digest(file = 'datasets/ecoles-quebec/preparation-api.R', algo = 'sha256'),
  prepare_utc = format(Sys.time(), '%Y-%m-%dT%H:%M:%SZ', tz = 'UTC'),
  lignes = nrow(table), colonnes = names(table)),
  file.path(dirname(brut), 'preparation.json'), pretty = TRUE, auto_unbox = TRUE)
Sys.setenv(DB_ECOLES_SNAPSHOT = sortie)
message('Instantané préparé : ', sortie,
  '\nLes activités utiliseront cette copie dans cette session R.',
  '\nPour la réutiliser dans une nouvelle session :\n',
  'Sys.setenv(DB_ECOLES_SNAPSHOT = ', encodeString(sortie, quote = '"'), ')')
