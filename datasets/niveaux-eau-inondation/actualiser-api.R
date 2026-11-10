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
source('datasets/niveaux-eau-inondation/preparation-api.R')
brut <- dq_acquire('niveaux-eau-inondation', '9433786e-5bed-4bc3-a9b9-f9efae4a6b77',
  fields = c('id_msp', 'date_obs', 'type_obs', 'long_wgs84', 'lat_wgs84', 'alt_m_cgvd', 'err_xy_cm', 'err_z_cm'))
table <- preparer_niveaux_api(brut)
sortie <- file.path(dirname(brut), 'table-activite.csv')
readr::write_csv(table, sortie, na = 'NA')
jsonlite::write_json(list(fichier_source = basename(brut), sha256_source = digest::digest(file = brut, algo = 'sha256'),
  fichier_prepare = basename(sortie), sha256_prepare = digest::digest(file = sortie, algo = 'sha256'),
  preparation = 'datasets/niveaux-eau-inondation/preparation-api.R',
  sha256_preparation = digest::digest(file = 'datasets/niveaux-eau-inondation/preparation-api.R', algo = 'sha256'),
  prepare_utc = format(Sys.time(), '%Y-%m-%dT%H:%M:%SZ', tz = 'UTC'),
  lignes = nrow(table), colonnes = names(table)),
  file.path(dirname(brut), 'preparation.json'), pretty = TRUE, auto_unbox = TRUE)
Sys.setenv(DB_NIVEAUX_SNAPSHOT = sortie)
message('Instantané préparé : ', sortie, '\nLes activités utiliseront cette copie dans cette session R.',
  '\nPour la réutiliser dans une nouvelle session :\n',
  'Sys.setenv(DB_NIVEAUX_SNAPSHOT = ', encodeString(sortie, quote = '"'), ')')
