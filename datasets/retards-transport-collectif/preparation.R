source("R/utils_downloads.R")
# Préparation : flux temps réel STM et ponctualité du transport collectif
# Source officielle : https://www.donneesquebec.ca/recherche/dataset/vmtl-stm-bus-temps-reel-gtfs-realtime
#
# Ce script ne fabrique pas de retards historiques. Le paquet CKAN vérifié
# expose une ressource GTFS-realtime accessible par le portail développeur STM.
# Sans clé API et sans protocole d'archivage, le nombre de lignes du flux
# historique est donc inconnu.

library(curl)
library(dplyr)
library(jsonlite)
library(readr)
library(tibble)

dataset_id <- "retards-transport-collectif"
api_url <- "https://www.donneesquebec.ca/recherche/api/3/action/package_show?id=vmtl-stm-bus-temps-reel-gtfs-realtime"
source_url <- "https://www.donneesquebec.ca/recherche/dataset/vmtl-stm-bus-temps-reel-gtfs-realtime"
developer_url <- "https://www.stm.info/fr/a-propos/developpeurs"
output_dir <- file.path("data", "processed", dataset_id)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0L || all(is.na(x))) y else x
}

clean_text <- function(x) {
  if (is.null(x) || length(x) == 0L) {
    return(NA_character_)
  }
  x <- as.character(x[[1]])
  if (is.na(x) || x == "") {
    return(NA_character_)
  }
  x <- gsub("[\u2013\u2014]", "-", enc2utf8(x), perl = TRUE)
  x <- gsub("\\s+", " ", x)
  trimws(x)
}

pluck_text <- function(x, name) {
  clean_text(x[[name]])
}

pluck_number <- function(x, name) {
  value <- x[[name]]
  if (is.null(value) || length(value) == 0L) {
    return(NA_real_)
  }
  suppressWarnings(as.numeric(value[[1]]))
}

read_ckan_package <- function(url) {
  tmp <- "data/raw/retards-transport-collectif/package_show.json"
  download_source(url, tmp, quiet = TRUE, handle = curl::new_handle(useragent = "Mozilla/5.0"))
  jsonlite::fromJSON(tmp, simplifyVector = FALSE)
}

ckan <- read_ckan_package(api_url)
stopifnot(isTRUE(ckan$success))

package <- ckan$result
resources <- package$resources
resource_rows <- lapply(seq_along(resources), function(i) {
  resource <- resources[[i]]
  resource_url <- pluck_text(resource, "url")
  tibble(
    resource_order = i,
    resource_id = pluck_text(resource, "id"),
    resource_name = pluck_text(resource, "name"),
    resource_description = pluck_text(resource, "description"),
    resource_format = pluck_text(resource, "format"),
    resource_url = resource_url,
    resource_last_modified = pluck_text(resource, "last_modified"),
    resource_metadata_modified = pluck_text(resource, "metadata_modified"),
    resource_size = pluck_number(resource, "size"),
    access_mode = if_else(
      grepl("developpeurs|developers", resource_url %||% "", ignore.case = TRUE),
      "portail développeur STM",
      "URL directe"
    )
  )
})

resources_tbl <- bind_rows(resource_rows)

n_gtfs_resources <- sum(grepl("GTFS", resources_tbl$resource_format %||% "", ignore.case = TRUE), na.rm = TRUE)
n_developer_portal_resources <- sum(resources_tbl$access_mode == "portail développeur STM", na.rm = TRUE)
n_direct_download_resources <- sum(
  !is.na(resources_tbl$resource_url) &
    resources_tbl$resource_url != "" &
    resources_tbl$access_mode != "portail développeur STM",
  na.rm = TRUE
)

summary_tbl <- tibble(
  access_date = as.character(Sys.Date()),
  package_id = pluck_text(package, "id"),
  package_name = pluck_text(package, "name"),
  title = pluck_text(package, "title"),
  organization = pluck_text(package$organization, "title"),
  license_title = pluck_text(package, "license_title"),
  license_id = pluck_text(package, "license_id"),
  package_metadata_modified = pluck_text(package, "metadata_modified"),
  n_resources_ckan = length(resources),
  n_gtfs_resources = n_gtfs_resources,
  n_developer_portal_resources = n_developer_portal_resources,
  n_direct_download_resources = n_direct_download_resources,
  source_requires_developer_account = n_developer_portal_resources > 0,
  historical_table_available_in_ckan = n_direct_download_resources > 0,
  source_url = source_url,
  api_url = api_url,
  developer_url = developer_url
)

gtfs_fields_tbl <- tribble(
  ~message_type, ~field_pedagogique, ~role_statistique, ~status,
  "TripUpdate", "route_id", "Identifiant de ligne ou parcours à utiliser pour les regroupements.", "Champ attendu dans la spécification GTFS-realtime; non validé dans le flux STM sans clé API.",
  "TripUpdate", "trip_id", "Identifiant de trajet, utile pour relier le temps réel aux horaires planifiés.", "Champ attendu dans la spécification GTFS-realtime; non validé dans le flux STM sans clé API.",
  "TripUpdate", "stop_id", "Arrêt auquel associer une mise à jour de temps de passage.", "Champ attendu dans la spécification GTFS-realtime; non validé dans le flux STM sans clé API.",
  "TripUpdate", "delay_seconds", "Retard brut en secondes lorsque la mise à jour de passage contient un délai.", "Champ possible dans StopTimeUpdate; à vérifier après extraction.",
  "VehiclePosition", "vehicle_id", "Identifiant du véhicule observé dans un instantané.", "Champ attendu dans la spécification GTFS-realtime; non validé dans le flux STM sans clé API.",
  "VehiclePosition", "latitude", "Coordonnée pour cartographier la position du véhicule.", "Champ attendu dans la spécification GTFS-realtime; non validé dans le flux STM sans clé API.",
  "VehiclePosition", "longitude", "Coordonnée pour cartographier la position du véhicule.", "Champ attendu dans la spécification GTFS-realtime; non validé dans le flux STM sans clé API.",
  "VehiclePosition", "occupancy_status", "Niveau d'occupation publié depuis la version 2 du flux, selon la documentation STM.", "Champ à vérifier après extraction du flux STM.",
  "Archivage local", "collection_time", "Horodatage ajouté par le protocole d'archivage pour analyser les séries temporelles.", "Variable dérivée par l'équipe pédagogique.",
  "Archivage local", "retard_minutes", "Conversion de delay_seconds en minutes pour les graphiques et les résumés.", "Variable dérivée; ne pas présenter comme colonne brute garantie."
)

archive_protocol_tbl <- tribble(
  ~step, ~action, ~point_de_controle,
  1, "Créer un compte sur le portail développeur STM et obtenir une clé API.", "Ne jamais publier la clé API dans Git, Quarto ou les fichiers remis aux étudiants.",
  2, "Collecter des instantanés à intervalle fixe pendant une période définie.", "Ajouter collection_time à chaque collecte; documenter le fuseau horaire.",
  3, "Parser les messages Protocol Buffers du flux GTFS-realtime.", "Conserver le type de message: TripUpdate, VehiclePosition ou Alert.",
  4, "Joindre les identifiants au GTFS statique de la STM lorsque l'analyse exige les noms de lignes ou d'arrêts.", "Vérifier que la période du GTFS statique correspond à la période des instantanés.",
  5, "Calculer retard_minutes seulement à partir d'un champ de délai effectivement présent.", "Documenter la formule et les observations exclues.",
  6, "Résumer les retards par ligne, par période et par sens de déplacement.", "Toujours rapporter le nombre d'observations par groupe.",
  7, "Présenter les limites avant d'interpréter la ponctualité.", "Distinguer couverture du flux, fréquence de collecte, données manquantes et performance réelle."
)

write_csv(resources_tbl, file.path(output_dir, "ressources_ckan_retards_transport.csv"))
write_csv(summary_tbl, file.path(output_dir, "resume_retards_transport.csv"))
write_csv(gtfs_fields_tbl, file.path(output_dir, "variables_gtfs_realtime_retards_transport.csv"))
write_csv(archive_protocol_tbl, file.path(output_dir, "protocole_archivage_retards_transport.csv"))

stopifnot(nrow(resources_tbl) >= 1)
stopifnot(nrow(summary_tbl) == 1)
stopifnot(summary_tbl$n_gtfs_resources >= 1)
stopifnot(summary_tbl$source_requires_developer_account)
stopifnot(nrow(gtfs_fields_tbl) == 10)
stopifnot(nrow(archive_protocol_tbl) == 7)

message("Préparation terminée : ", output_dir)

record_preparation("retards-transport-collectif")
