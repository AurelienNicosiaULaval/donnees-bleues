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
source('datasets/arbres-publics-montreal/preparation-api.R')
brut <- dq_acquire('arbres-publics-montreal', '64e28fe6-ef37-437a-972d-d1d3f1f7d891',
  fields = c('ARROND_NOM', 'Essence_fr', 'DHP'))
table <- preparer_arbres_api(brut)
sortie <- file.path(dirname(brut), 'table-activite.csv')
readr::write_csv(table, sortie, na = 'NA')
jsonlite::write_json(list(fichier_source = basename(brut), sha256_source = digest::digest(file = brut, algo = 'sha256'),
  fichier_prepare = basename(sortie), sha256_prepare = digest::digest(file = sortie, algo = 'sha256'),
  preparation = 'datasets/arbres-publics-montreal/preparation-api.R',
  sha256_preparation = digest::digest(file = 'datasets/arbres-publics-montreal/preparation-api.R', algo = 'sha256'),
  prepare_utc = format(Sys.time(), '%Y-%m-%dT%H:%M:%SZ', tz = 'UTC'),
  lignes = nrow(table), colonnes = names(table)),
  file.path(dirname(brut), 'preparation.json'), pretty = TRUE, auto_unbox = TRUE)
Sys.setenv(DB_ARBRES_SNAPSHOT = sortie)
message('Instantané préparé : ', sortie, '\nLes activités utiliseront cette copie dans cette session R.',
  '\nPour la réutiliser dans une nouvelle session :\n',
  'Sys.setenv(DB_ARBRES_SNAPSHOT = ', encodeString(sortie, quote = '"'), ')')
