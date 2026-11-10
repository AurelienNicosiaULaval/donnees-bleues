# L’API repère le fichier annuel SAAQ; le téléchargement d’environ 905 Mo reste local.
library(jsonlite)
library(httr2)
library(readr)
library(digest)
library(xml2)
library(dplyr)
library(tibble)
source('R/utils_downloads.R')
source('R/utils_ckan.R')
source('R/utils_donnees_quebec.R')
source('datasets/vehicules-canada-2025/preparation-api.R')
ancien <- getOption('timeout'); options(timeout = max(ancien, 1200))
brut <- tryCatch(dq_acquire('vehicules-canada-2025', '36e97894-fd4a-46fd-ab89-9e46329d60a9'),
                 finally = options(timeout = ancien))
table <- preparer_parc_api(brut)
sortie <- file.path(dirname(brut), 'parc-activite.csv')
readr::write_csv(table, sortie, na = '')
if (!identical(digest::digest(file = sortie, algo = 'sha256'), '4fb91d7190b9c6c62d97c2d23168a1c318206a969bfe3d255bc0d1c42cf30dca'))
  stop('Les comptes reconstruits diffèrent de la table de référence.', call. = FALSE)
jsonlite::write_json(list(sha256_source = digest::digest(file = brut, algo = 'sha256'),
  sha256_table = digest::digest(file = sortie, algo = 'sha256'), lignes = nrow(table),
  prepare_utc = format(Sys.time(), '%Y-%m-%dT%H:%M:%SZ', tz = 'UTC')),
  file.path(dirname(brut), 'preparation.json'), pretty = TRUE, auto_unbox = TRUE)
Sys.setenv(DB_PARC_SAAQ_SNAPSHOT = sortie)
message('Table du parc préparée : ', sortie, '\nElle sera utilisée dans cette session R.')
