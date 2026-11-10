# Acquérir uniquement les champs utilisés dans les activités.
library(jsonlite)
library(httr2)
library(readr)
library(digest)
library(xml2)
library(dplyr)
source('R/utils_downloads.R')
source('R/utils_ckan.R')
source('R/utils_donnees_quebec.R')
source('datasets/actes-criminels-montreal/preparation-api.R')
brut <- dq_acquire('actes-criminels-montreal', 'c6f482bf-bf0f-4960-8b2f-9982c211addd',
  fields = c('CATEGORIE', 'DATE', 'QUART'))
table <- preparer_actes_api(brut)
sortie <- file.path(dirname(brut), 'actes-activite.csv')
write_csv(table, sortie, na = 'NA')
jsonlite::write_json(list(fichier_source = basename(brut), sha256_source = digest::digest(file = brut, algo = 'sha256'),
  fichier_prepare = basename(sortie), sha256_prepare = digest::digest(file = sortie, algo = 'sha256'),
  preparation = 'datasets/actes-criminels-montreal/preparation-api.R',
  sha256_preparation = digest::digest(file = 'datasets/actes-criminels-montreal/preparation-api.R', algo = 'sha256'),
  prepare_utc = format(Sys.time(), '%Y-%m-%dT%H:%M:%SZ', tz = 'UTC'),
  lignes = nrow(table), colonnes = names(table)),
  file.path(dirname(brut), 'preparation.json'), pretty = TRUE, auto_unbox = TRUE)
Sys.setenv(DB_ACTES_SNAPSHOT = sortie)
message('Instantané préparé : ', sortie,
  '\nLes activités utiliseront cette copie dans cette session R.',
  '\nPour la réutiliser dans une nouvelle session :\n',
  'Sys.setenv(DB_ACTES_SNAPSHOT = ', encodeString(sortie, quote = '"'), ')')
