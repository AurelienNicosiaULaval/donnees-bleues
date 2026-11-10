# Vérifier l'index API et utiliser la copie pédagogique datée, sans télécharger le XML.
library(jsonlite)
library(httr2)
library(readr)
library(digest)
library(xml2)
library(dplyr)
library(tidyr)
source('R/utils_downloads.R')
source('R/utils_ckan.R')
source('datasets/maisons-quebec/preparation-api.R')
rejouer_maisons <- function() {
  archive <- 'datasets/maisons-quebec/snapshots/20261110T191348Z/source-api.zip'
  if (!identical(digest::digest(file=archive,algo='sha256'),trimws(readLines(paste0(archive,'.sha256'))[1])))
    stop('Archive de référence altérée.',call.=FALSE)
  chemins <- utils::unzip(archive,list=TRUE)$Name
  if (any(grepl('(^/|(^|/)\\.\\.(/|$))',chemins))) stop('Chemin ZIP invalide.',call.=FALSE)
  extrait <- tempfile('maisons-api-');dir.create(extrait);on.exit(unlink(extrait,recursive=TRUE),add=TRUE)
  utils::unzip(archive,exdir=extrait)
  index <- file.path(extrait,'index','donnees-api.csv')
  ancien <- Sys.getenv('DB_OFFLINE',unset=NA_character_)
  on.exit(if(is.na(ancien)) Sys.unsetenv('DB_OFFLINE') else Sys.setenv(DB_OFFLINE=ancien),add=TRUE)
  Sys.setenv(DB_OFFLINE='true');ckan_datastore_download('c0e65c47-fcc1-40e4-bc2e-7baa74bc164a',index)
  url_maisons_api(index)
  provenance <- jsonlite::read_json(file.path(extrait,'provenance-api.json'))
  sample <- file.path(extrait,'maisons-activite.csv')
  if (!identical(digest::digest(file=sample,algo='sha256'),provenance$sha256_table) ||
      !identical(provenance$sha256_xml,'971896db6bf6bcae5a711bbd4b2b33f945b770d237bd4164d8f4f5cd54feff9a'))
    stop('Copie pédagogique ou empreinte du XML invalide.',call.=FALSE)
  dossier <- 'data/raw/rejeu-api/maisons-quebec/20261110T191348Z'
  dir.create(dossier,recursive=TRUE,showWarnings=FALSE)
  sortie <- file.path(dossier,'table-activite.csv')
  if (file.exists(sortie)) {
    if (!identical(digest::digest(file=sortie,algo='sha256'),provenance$sha256_table))
      stop('La table existante diffère de la copie datée.',call.=FALSE)
  } else if (!file.copy(sample,sortie)) stop('Impossible de conserver la copie pédagogique.',call.=FALSE)
  jsonlite::write_json(provenance,file.path(dossier,'provenance-api.json'),auto_unbox=TRUE,pretty=TRUE)
  Sys.setenv(DB_MAISONS_SNAPSHOT=sortie)
  message('Copie pédagogique vérifiée : ',sortie,
    '\nElle sera utilisée dans cette session R. Le XML complet n’est pas inclus dans la trousse.',
    '\nPour la réutiliser dans une nouvelle session :\n',
    'Sys.setenv(DB_MAISONS_SNAPSHOT = ',encodeString(sortie,quote='"'),')')
  invisible(sortie)
}
rejouer_maisons()
