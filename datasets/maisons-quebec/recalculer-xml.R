# Refaire le tirage depuis le XML conservé sur votre ordinateur et l'index daté de la trousse.
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
source('datasets/maisons-quebec/enregistrer-api.R')
recalculer_maisons <- function() {
  xml <- Sys.getenv('DB_MAISONS_XML',unset='')
  if (!nzchar(xml) || !file.exists(xml))
    stop('Indiquer le chemin du XML local avec Sys.setenv(DB_MAISONS_XML = "chemin/role_quebec_2026.xml").',call.=FALSE)
  archive <- 'datasets/maisons-quebec/snapshots/20261110T191348Z/source-api.zip'
  if (!identical(digest::digest(file=archive,algo='sha256'),trimws(readLines(paste0(archive,'.sha256'))[1])))
    stop('Archive de référence altérée.',call.=FALSE)
  chemins <- utils::unzip(archive,list=TRUE)$Name
  if (any(grepl('(^/|(^|/)\\.\\.(/|$))',chemins))) stop('Chemin ZIP invalide.',call.=FALSE)
  extrait <- tempfile('maisons-index-');dir.create(extrait);on.exit(unlink(extrait,recursive=TRUE),add=TRUE)
  utils::unzip(archive,exdir=extrait)
  index <- file.path(extrait,'index','donnees-api.csv')
  ancien <- Sys.getenv('DB_OFFLINE',unset=NA_character_)
  on.exit(if(is.na(ancien)) Sys.unsetenv('DB_OFFLINE') else Sys.setenv(DB_OFFLINE=ancien),add=TRUE)
  Sys.setenv(DB_OFFLINE='true');ckan_datastore_download('c0e65c47-fcc1-40e4-bc2e-7baa74bc164a',index)
  resultat <- preparer_maisons_api(index,xml)
  recus <- list(index=jsonlite::read_json(paste0(index,'.source.json')),
    xml=list(source_url=url_maisons_api(index),sha256=resultat$source_xml_sha256,mode='fichier local vérifié'))
  enregistrer_maisons_api(resultat,recus,'data/raw/recalcul-api/maisons-quebec/20261110T191348Z')
}
recalculer_maisons()
