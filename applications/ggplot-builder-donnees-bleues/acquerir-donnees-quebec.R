# Acquisition facultative avec Internet, depuis la racine du projet extrait.
# Installer au besoin : install.packages(c("jsonlite", "httr2", "readr", "digest", "xml2"))
# Exécuter une première fois pour afficher les ressources, puis renseigner resource_id.
# Les nouvelles sources sont conservées à part; les analyses gardent leurs fichiers figés.
library(jsonlite)
library(httr2)
library(readr)
library(digest)
library(xml2)
source("R/utils_downloads.R")
source("R/utils_ckan.R")
source("R/utils_donnees_quebec.R")
dataset_id <- "arbres-quebec"
resource_id <- ""
if (!nzchar(resource_id)) {
  print(dq_resource_options(dataset_id), row.names = FALSE)
} else {
  fichier <- dq_acquire(dataset_id, resource_id)
  message("Source acquise : ", fichier)
}
