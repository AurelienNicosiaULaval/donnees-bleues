source("R/utils_downloads.R")
# Préparation : stations du Réseau de surveillance de la qualité de l'air du Québec
# Source officielle : Données Québec, paquet CKAN 8656ad05-c174-41c5-9ed7-8c69d308beb9.

library(dplyr)
library(jsonlite)
library(lubridate)
library(readr)
library(stringr)
library(tidyr)

raw_dir <- "data/raw/qualite-air"
processed_dir <- "data/processed/qualite-air"
dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(processed_dir, recursive = TRUE, showWarnings = FALSE)

access_date <- Sys.Date()
source_page <- "https://www.donneesquebec.ca/recherche/dataset/rsqaq-stations"
source_secondary_url <- "https://www.environnement.gouv.qc.ca/air/reseau-surveillance/Carte.asp"
package_api <- "https://www.donneesquebec.ca/recherche/api/3/action/package_show?id=rsqaq-stations"
csv_url <- "https://www.donneesquebec.ca/recherche/dataset/8656ad05-c174-41c5-9ed7-8c69d308beb9/resource/cebea532-a9e0-4a39-8c2d-54f33d937c73/download/rsqaq_stations_de_la_qualite_de_lair.csv"

package_json_path <- file.path(raw_dir, "package_show_rsqaq_stations.json")
csv_raw_path <- file.path(raw_dir, "rsqaq_stations_de_la_qualite_de_lair.csv")

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
    description = description,
    last_modified = as.character(last_modified),
    size = suppressWarnings(as.numeric(size))
  )

regions <- tibble::tribble(
  ~region_code, ~region_administrative,
  1L, "Bas-Saint-Laurent",
  2L, "Saguenay-Lac-Saint-Jean",
  3L, "Capitale-Nationale",
  4L, "Mauricie",
  5L, "Estrie",
  6L, "Montréal",
  7L, "Outaouais",
  8L, "Abitibi-Témiscamingue",
  9L, "Côte-Nord",
  10L, "Nord-du-Québec",
  11L, "Gaspésie-Iles-de-la-Madeleine",
  12L, "Chaudière-Appalaches",
  13L, "Laval",
  14L, "Lanaudière",
  15L, "Laurentides",
  16L, "Montérégie",
  17L, "Centre-du-Québec"
)

source_data <- read_csv(
  csv_raw_path,
  locale = locale(encoding = "UTF-8"),
  show_col_types = FALSE
)

stations <- source_data |>
  transmute(
    station_id = as.integer(ID_STATION),
    station_name = NOM_STATION,
    region_code = as.integer(RA),
    adresse = ADRESSE,
    municipalite = MUNICIPALITE,
    type_milieu = TYPE_MILIEU,
    date_ouverture = as.Date(DATE_OUVERTURE),
    date_fermeture = as.Date(DATE_FERMETURE),
    latitude = as.numeric(LATITUDE),
    longitude = as.numeric(LONGITUDE),
    annee_ouverture = year(date_ouverture),
    annee_fermeture = year(date_fermeture),
    decennie_ouverture = paste0(floor(annee_ouverture / 10) * 10, "s"),
    station_sans_date_fermeture = is.na(date_fermeture),
    statut_prepare = if_else(
      is.na(date_fermeture) | date_fermeture > access_date,
      "Sans date de fermeture au 2026-06-21",
      "Fermée"
    ),
    duree_fermee_jours = as.numeric(date_fermeture - date_ouverture),
    duree_observee_jours = as.numeric(coalesce(date_fermeture, access_date) - date_ouverture),
    source_csv_url = csv_url,
    access_date = access_date
  ) |>
  left_join(regions, by = "region_code") |>
  relocate(region_administrative, .after = region_code) |>
  arrange(region_code, municipalite, station_id)

missing_summary <- stations |>
  summarise(across(everything(), ~ sum(is.na(.x)))) |>
  pivot_longer(
    cols = everything(),
    names_to = "variable",
    values_to = "n_missing"
  ) |>
  mutate(
    n_rows = nrow(stations),
    pct_missing = round(100 * n_missing / n_rows, 2)
  ) |>
  arrange(desc(n_missing), variable)

summary_by_type <- stations |>
  group_by(type_milieu) |>
  summarise(
    n_stations = n(),
    n_sans_date_fermeture = sum(station_sans_date_fermeture),
    n_fermees = sum(!station_sans_date_fermeture),
    premiere_ouverture = min(date_ouverture, na.rm = TRUE),
    derniere_ouverture = max(date_ouverture, na.rm = TRUE),
    duree_fermee_mediane_jours = median(duree_fermee_jours, na.rm = TRUE),
    .groups = "drop"
  ) |>
  arrange(desc(n_stations))

summary_by_region <- stations |>
  group_by(region_code, region_administrative) |>
  summarise(
    n_stations = n(),
    n_sans_date_fermeture = sum(station_sans_date_fermeture),
    n_fermees = sum(!station_sans_date_fermeture),
    n_types_milieu = n_distinct(type_milieu),
    premiere_ouverture = min(date_ouverture, na.rm = TRUE),
    derniere_ouverture = max(date_ouverture, na.rm = TRUE),
    .groups = "drop"
  ) |>
  arrange(desc(n_sans_date_fermeture), desc(n_stations), region_code)

summary_by_decade <- stations |>
  count(decennie_ouverture, name = "n_stations") |>
  arrange(decennie_ouverture)

stations_sans_date_fermeture <- stations |>
  filter(station_sans_date_fermeture) |>
  select(
    station_id,
    station_name,
    region_code,
    region_administrative,
    municipalite,
    type_milieu,
    date_ouverture,
    latitude,
    longitude
  ) |>
  arrange(region_code, municipalite, station_id)

dataset_summary <- tibble::tibble(
  metric = c(
    "source_page",
    "source_secondary_url",
    "package_api",
    "csv_url",
    "access_date",
    "package_id",
    "metadata_modified",
    "csv_resource_last_modified",
    "csv_resource_size",
    "n_resources_ckan",
    "n_rows_source",
    "n_columns_source",
    "n_rows_prepared",
    "n_columns_prepared",
    "n_regions",
    "n_types_milieu",
    "n_stations_sans_date_fermeture",
    "n_stations_fermees",
    "first_opening_date",
    "last_opening_date",
    "last_closing_date"
  ),
  value = c(
    source_page,
    source_secondary_url,
    package_api,
    csv_url,
    as.character(access_date),
    package$result$id,
    as.character(package$result$metadata_modified),
    resources$last_modified[resources$url == csv_url],
    as.character(resources$size[resources$url == csv_url]),
    as.character(nrow(resources)),
    as.character(nrow(source_data)),
    as.character(ncol(source_data)),
    as.character(nrow(stations)),
    as.character(ncol(stations)),
    as.character(n_distinct(stations$region_code)),
    as.character(n_distinct(stations$type_milieu)),
    as.character(sum(stations$station_sans_date_fermeture)),
    as.character(sum(!stations$station_sans_date_fermeture)),
    as.character(min(stations$date_ouverture, na.rm = TRUE)),
    as.character(max(stations$date_ouverture, na.rm = TRUE)),
    as.character(max(stations$date_fermeture, na.rm = TRUE))
  )
)

stopifnot(
  nrow(resources) == 1,
  nrow(source_data) == 245,
  ncol(source_data) == 10,
  nrow(stations) == 245,
  ncol(stations) == 20,
  n_distinct(stations$region_code) == 16,
  n_distinct(stations$type_milieu) == 3,
  sum(stations$station_sans_date_fermeture) == 51,
  sum(!stations$station_sans_date_fermeture) == 194,
  min(stations$date_ouverture) == as.Date("1975-01-01"),
  max(stations$date_ouverture) == as.Date("2024-07-16"),
  max(stations$date_fermeture, na.rm = TRUE) == as.Date("2025-07-12"),
  setequal(stations$type_milieu, c("Agricole", "Forêt", "Urbain")),
  !any(is.na(stations$region_administrative))
)

write_csv(
  stations,
  file.path(processed_dir, "rsqaq_stations.csv")
)

write_csv(
  resources,
  file.path(processed_dir, "ressources_rsqaq_stations.csv")
)

write_csv(
  missing_summary,
  file.path(processed_dir, "valeurs_manquantes_rsqaq_stations.csv")
)

write_csv(
  summary_by_type,
  file.path(processed_dir, "resume_types_milieu_rsqaq_stations.csv")
)

write_csv(
  summary_by_region,
  file.path(processed_dir, "resume_regions_rsqaq_stations.csv")
)

write_csv(
  summary_by_decade,
  file.path(processed_dir, "resume_decennies_ouverture_rsqaq_stations.csv")
)

write_csv(
  stations_sans_date_fermeture,
  file.path(processed_dir, "stations_sans_date_fermeture_rsqaq.csv")
)

write_csv(
  dataset_summary,
  file.path(processed_dir, "resume_rsqaq_stations.csv")
)

message("Source : ", source_page)
message("API CKAN : ", package_api)
message("Fichier préparé : ", file.path(processed_dir, "rsqaq_stations.csv"))
message("Stations préparées : ", nrow(stations))
message("Stations sans date de fermeture : ", sum(stations$station_sans_date_fermeture))

record_preparation("qualite-air")
