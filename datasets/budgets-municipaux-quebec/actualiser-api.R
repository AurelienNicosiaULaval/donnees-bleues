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
source('datasets/budgets-municipaux-quebec/preparation-api.R')
brut <- dq_acquire('budgets-municipaux-quebec', '15192f34-a635-47f5-aaf9-eb1621d65b2e',
  fields = c('cod_geo', 'nom_organisme', 'nom_ra', 'population', 'desc_cp', 'FIALX02005', 'FIALX02006', 'FIALX02007', 'FIALX02010', 'FIALX02097'))
table <- preparer_budgets_api(brut)
sortie <- file.path(dirname(brut), 'table-activite.csv')
readr::write_csv(table, sortie, na = 'NA')
jsonlite::write_json(list(fichier_source = basename(brut), sha256_source = digest::digest(file = brut, algo = 'sha256'),
  fichier_prepare = basename(sortie), sha256_prepare = digest::digest(file = sortie, algo = 'sha256'),
  preparation = 'datasets/budgets-municipaux-quebec/preparation-api.R',
  sha256_preparation = digest::digest(file = 'datasets/budgets-municipaux-quebec/preparation-api.R', algo = 'sha256'),
  prepare_utc = format(Sys.time(), '%Y-%m-%dT%H:%M:%SZ', tz = 'UTC'),
  lignes = nrow(table), colonnes = names(table)),
  file.path(dirname(brut), 'preparation.json'), pretty = TRUE, auto_unbox = TRUE)
Sys.setenv(DB_BUDGETS_SNAPSHOT = sortie)
message('Instantané préparé : ', sortie, '\nLes activités utiliseront cette copie dans cette session R.',
  '\nPour la réutiliser dans une nouvelle session :\n',
  'Sys.setenv(DB_BUDGETS_SNAPSHOT = ', encodeString(sortie, quote = '"'), ')')
