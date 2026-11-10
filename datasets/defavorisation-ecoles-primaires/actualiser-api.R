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
source('datasets/defavorisation-ecoles-primaires/preparation-api.R')
brut <- dq_acquire('defavorisation-ecoles-primaires', '6c5d4a5d-ba3b-40a6-b570-916f43ab622c',
  fields = c('Code_Org', 'Nom_Org', 'IMSE', 'Rang_Decile_IMSE', 'SFR', 'Rang_Decile_SFR', 'Nbre_Eleves', 'Diffusion', 'Annee_Scol'))
table <- preparer_defavorisation_api(brut)
sortie <- file.path(dirname(brut), 'table-activite.csv')
readr::write_csv(table, sortie, na = 'NA')
jsonlite::write_json(list(fichier_source = basename(brut), sha256_source = digest::digest(file = brut, algo = 'sha256'),
  fichier_prepare = basename(sortie), sha256_prepare = digest::digest(file = sortie, algo = 'sha256'),
  preparation = 'datasets/defavorisation-ecoles-primaires/preparation-api.R',
  sha256_preparation = digest::digest(file = 'datasets/defavorisation-ecoles-primaires/preparation-api.R', algo = 'sha256'),
  prepare_utc = format(Sys.time(), '%Y-%m-%dT%H:%M:%SZ', tz = 'UTC'),
  lignes = nrow(table), colonnes = names(table)),
  file.path(dirname(brut), 'preparation.json'), pretty = TRUE, auto_unbox = TRUE)
Sys.setenv(DB_DEFAVORISATION_SNAPSHOT = sortie)
message('Instantané préparé : ', sortie, '\nLes activités utiliseront cette copie dans cette session R.',
  '\nPour la réutiliser dans une nouvelle session :\n',
  'Sys.setenv(DB_DEFAVORISATION_SNAPSHOT = ', encodeString(sortie, quote = '"'), ')')
