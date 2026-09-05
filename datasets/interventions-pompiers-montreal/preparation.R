source("R/utils_downloads.R")
# Préparer le jeu de données : Interventions des pompiers de Montréal.

library(dplyr)
library(lubridate)
library(readr)

dataset_id <- "interventions-pompiers-montreal"
raw_dir <- file.path("data", "raw", dataset_id)
processed_dir <- file.path("data", "processed", dataset_id)
dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(processed_dir, recursive = TRUE, showWarnings = FALSE)

official_source_url <- "https://donnees.montreal.ca/fr/dataset/interventions-service-securite-incendie-montreal"
current_csv_url <- "https://donnees.montreal.ca/dataset/2fc8a2b9-1556-410e-a118-c46e97e9f19e/resource/71e86320-e35c-4b4c-878a-e52124294355/download/donneesouvertes-interventions-sim.csv"
raw_path <- file.path(raw_dir, "donneesouvertes-interventions-sim.csv")
processed_path <- file.path(processed_dir, "interventions_pompiers_montreal.csv")

download_source(current_csv_url, raw_path, mode = "wb", quiet = TRUE)

interventions <- read_csv(raw_path, show_col_types = FALSE) |>
  transmute(
    creation_date_time = ymd_hms(.data$CREATION_DATE_TIME, quiet = TRUE),
    incident_type = .data$INCIDENT_TYPE_DESC,
    description_groupe = .data$DESCRIPTION_GROUPE,
    caserne = as.character(.data$CASERNE),
    nom_ville = .data$NOM_VILLE,
    nom_arrond = .data$NOM_ARROND,
    division = as.character(.data$DIVISION),
    nombre_unites = suppressWarnings(as.integer(.data$NOMBRE_UNITES))
  ) |>
  arrange(.data$creation_date_time, .data$description_groupe)

if (nrow(interventions) == 0L) {
  stop("La ressource officielle ne contient aucune intervention.", call. = FALSE)
}

write_csv(interventions, processed_path)

message("Source : ", official_source_url)
message("Fichier préparé : ", processed_path)
message("Interventions préparées : ", nrow(interventions))

record_preparation("interventions-pompiers-montreal")
