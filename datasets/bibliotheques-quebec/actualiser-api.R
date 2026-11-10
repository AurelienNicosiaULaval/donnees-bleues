# Récupérer un nouvel instantané et préparer les données des deux activités.
# À lancer depuis la racine de la trousse avec une connexion Internet.
library(jsonlite)
library(httr2)
library(readr)
library(digest)
library(xml2)
library(dplyr)
library(stringi)
source('R/utils_downloads.R')
source('R/utils_ckan.R')
source('R/utils_donnees_quebec.R')
source('datasets/bibliotheques-quebec/preparation-api.R')

brut <- dq_acquire('bibliotheques-quebec', '01183d3e-c79c-4d09-915c-f35ffe4dfda8')
table <- preparer_bibliotheques_api(brut)
if (!nrow(table) || !any(is.finite(table$visites_par_habitant)))
  stop('La ressource ne permet pas de réaliser les activités.', call. = FALSE)
sortie <- file.path(dirname(brut), 'bibliotheques-activite.csv')
write_csv(table, sortie, na = 'NA')
jsonlite::write_json(list(
  fichier_source = basename(brut), sha256_source = digest::digest(file = brut, algo = 'sha256'),
  fichier_prepare = basename(sortie), sha256_prepare = digest::digest(file = sortie, algo = 'sha256'),
  preparation = 'datasets/bibliotheques-quebec/preparation-api.R',
  sha256_preparation = digest::digest(file = 'datasets/bibliotheques-quebec/preparation-api.R', algo = 'sha256'),
  prepare_utc = format(Sys.time(), '%Y-%m-%dT%H:%M:%SZ', tz = 'UTC'),
  lignes = nrow(table), colonnes = names(table)),
  file.path(dirname(brut), 'preparation.json'), pretty = TRUE, auto_unbox = TRUE)
Sys.setenv(DB_BIBLIOTHEQUES_SNAPSHOT = sortie)
message('Instantané préparé : ', sortie,
        '\nLes activités utiliseront cette copie dans cette session R.',
        '\nPour la réutiliser dans une nouvelle session, exécuter :\n',
        'Sys.setenv(DB_BIBLIOTHEQUES_SNAPSHOT = ', encodeString(sortie, quote = '"'), ')')
