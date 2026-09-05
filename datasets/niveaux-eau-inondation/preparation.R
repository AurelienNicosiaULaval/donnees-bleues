source("R/utils_downloads.R")
# Préparation : Niveaux d'eau lors d'une inondation
# Source officielle : Données Québec, paquet CKAN 1935bceb-4045-436e-9c1b-3997b55752a8.

library(dplyr)
library(jsonlite)
library(lubridate)
library(readr)
library(stringr)
library(tidyr)

raw_dir <- "data/raw/niveaux-eau-inondation"
processed_dir <- "data/processed/niveaux-eau-inondation"
dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(processed_dir, recursive = TRUE, showWarnings = FALSE)

access_date <- as.character(Sys.Date())
source_page <- "https://www.donneesquebec.ca/recherche/dataset/niveaux-deau-inondation-msp"
package_api <- "https://www.donneesquebec.ca/recherche/api/3/action/package_show?id=niveaux-deau-inondation-msp"
csv_url <- "https://geoegl.msp.gouv.qc.ca/apis/wss/historiquesc.fcgi?service=wfs&version=1.1.0&request=getfeature&typename=MSP_DELAISS_CRUE_PUBLIC_P&outputformat=csv"

package_json_path <- file.path(raw_dir, "package_show_niveaux_eau_inondation.json")
csv_raw_path <- file.path(raw_dir, "niveaux_eau_inondation.csv")

download_source(package_api, package_json_path, mode = "wb", quiet = TRUE)
download_source(csv_url, csv_raw_path, mode = "wb", quiet = TRUE)

package <- fromJSON(package_json_path)
if (!isTRUE(package$success)) {
  stop("L'API CKAN n'a pas retourné success = TRUE.", call. = FALSE)
}

resources <- package$result$resources |>
  transmute(
    resource_id = id,
    resource_name = name,
    format = toupper(format),
    url = url,
    last_modified = as.character(last_modified)
  )

source_data <- read_csv(csv_raw_path, show_col_types = FALSE)

extract_href <- function(x) {
  str_match(x, 'href="([^"]+)"')[, 2]
}

extract_link_text <- function(x) {
  str_match(x, ">([^<]+)</a>")[, 2]
}

niveaux_eau <- source_data |>
  mutate(
    rapport_url = extract_href(rapport),
    rapport_code = coalesce(extract_link_text(rapport), nom_mandataire),
    annee_obs = year(date_obs),
    date_heure_obs_parsee = ymd_hms(date_heure_obs, quiet = TRUE),
    has_time = !is.na(heure_obs),
    has_report_name = !is.na(nom_mandataire) & nom_mandataire != "",
    has_report_url = !is.na(rapport_url) & rapport_url != "",
    has_coordinates = !is.na(long_wgs84) & !is.na(lat_wgs84),
    has_altitude = !is.na(alt_m_cgvd),
    type_observation = case_when(
      type_obs == "MAX" ~ "Niveau maximal atteint",
      type_obs == "ACT" ~ "Niveau observé lors de la visite",
      TRUE ~ "Autre ou non documenté"
    ),
    source_csv_url = csv_url,
    access_date = access_date
  ) |>
  select(
    id_msp,
    rapport_code,
    rapport_url,
    nom_mandataire,
    date_obs,
    heure_obs,
    date_heure_obs_parsee,
    annee_obs,
    type_obs,
    type_observation,
    marq_sol,
    prec_marq,
    glace_chen,
    long_wgs84,
    lat_wgs84,
    err_xy_cm,
    alt_m_cgvd,
    err_z_cm,
    producteur,
    version,
    has_time,
    has_report_name,
    has_report_url,
    has_coordinates,
    has_altitude,
    source_csv_url,
    access_date
  ) |>
  arrange(date_obs, id_msp)

missing_summary <- niveaux_eau |>
  summarise(across(everything(), ~ sum(is.na(.x)))) |>
  pivot_longer(
    cols = everything(),
    names_to = "variable",
    values_to = "n_missing"
  ) |>
  mutate(
    n_rows = nrow(niveaux_eau),
    pct_missing = round(100 * n_missing / n_rows, 2)
  ) |>
  arrange(desc(n_missing), variable)

summary_by_year <- niveaux_eau |>
  count(annee_obs, type_obs, name = "n_observations") |>
  arrange(annee_obs, type_obs)

summary_by_type <- niveaux_eau |>
  group_by(type_obs, type_observation) |>
  summarise(
    n_observations = n(),
    altitude_min = min(alt_m_cgvd, na.rm = TRUE),
    altitude_mediane = median(alt_m_cgvd, na.rm = TRUE),
    altitude_max = max(alt_m_cgvd, na.rm = TRUE),
    erreur_xy_mediane_cm = median(err_xy_cm, na.rm = TRUE),
    erreur_z_mediane_cm = median(err_z_cm, na.rm = TRUE),
    .groups = "drop"
  ) |>
  arrange(desc(n_observations))

dataset_summary <- tibble::tibble(
  metric = c(
    "source_page",
    "package_api",
    "csv_url",
    "access_date",
    "source_version",
    "n_rows",
    "n_columns_prepared",
    "n_resources_ckan",
    "date_min",
    "date_max",
    "n_report_names",
    "n_type_max",
    "n_type_act",
    "altitude_min",
    "altitude_max",
    "median_error_xy_cm",
    "median_error_z_cm"
  ),
  value = c(
    source_page,
    package_api,
    csv_url,
    access_date,
    paste(unique(as.character(niveaux_eau$version)), collapse = "; "),
    as.character(nrow(niveaux_eau)),
    as.character(ncol(niveaux_eau)),
    as.character(nrow(resources)),
    as.character(min(niveaux_eau$date_obs, na.rm = TRUE)),
    as.character(max(niveaux_eau$date_obs, na.rm = TRUE)),
    as.character(n_distinct(niveaux_eau$nom_mandataire, na.rm = TRUE)),
    as.character(sum(niveaux_eau$type_obs == "MAX")),
    as.character(sum(niveaux_eau$type_obs == "ACT")),
    as.character(min(niveaux_eau$alt_m_cgvd, na.rm = TRUE)),
    as.character(max(niveaux_eau$alt_m_cgvd, na.rm = TRUE)),
    as.character(median(niveaux_eau$err_xy_cm, na.rm = TRUE)),
    as.character(median(niveaux_eau$err_z_cm, na.rm = TRUE))
  )
)

stopifnot(
  nrow(resources) == 7,
  nrow(niveaux_eau) == 1500,
  ncol(source_data) == 17,
  ncol(niveaux_eau) == 27,
  min(niveaux_eau$date_obs, na.rm = TRUE) == as.Date("2017-04-30"),
  max(niveaux_eau$date_obs, na.rm = TRUE) == as.Date("2025-07-14"),
  all(niveaux_eau$has_coordinates),
  all(niveaux_eau$has_altitude),
  sum(niveaux_eau$type_obs == "MAX") == 1195,
  sum(niveaux_eau$type_obs == "ACT") == 305,
  sum(is.na(niveaux_eau$heure_obs)) == 59,
  sum(is.na(niveaux_eau$nom_mandataire)) == 36,
  max(niveaux_eau$version, na.rm = TRUE) == as.Date("2026-05-12")
)

write_csv(
  niveaux_eau,
  file.path(processed_dir, "niveaux_eau_inondation.csv")
)

write_csv(
  resources,
  file.path(processed_dir, "ressources_niveaux_eau_inondation.csv")
)

write_csv(
  missing_summary,
  file.path(processed_dir, "valeurs_manquantes_niveaux_eau_inondation.csv")
)

write_csv(
  summary_by_year,
  file.path(processed_dir, "resume_annee_niveaux_eau_inondation.csv")
)

write_csv(
  summary_by_type,
  file.path(processed_dir, "resume_type_niveaux_eau_inondation.csv")
)

write_csv(
  dataset_summary,
  file.path(processed_dir, "resume_niveaux_eau_inondation.csv")
)

message("Source : ", source_page)
message("API CKAN : ", package_api)
message("Fichier préparé : ", file.path(processed_dir, "niveaux_eau_inondation.csv"))
message("Observations préparées : ", nrow(niveaux_eau))
message("Ressources CKAN documentées : ", nrow(resources))

record_preparation("niveaux-eau-inondation")
