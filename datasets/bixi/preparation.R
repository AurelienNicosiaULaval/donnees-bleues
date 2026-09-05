source("R/utils_downloads.R")
# Préparation : instantané des stations BIXI depuis les flux GBFS.
# Source officielle : Données Québec / BIXI Montréal,
# paquet CKAN 89fdc53c-cf70-485f-ab1a-9b10044d9f15.

library(dplyr)
library(jsonlite)
library(readr)
library(tidyr)

find_project_root <- function(path = getwd()) {
  current <- normalizePath(path, mustWork = FALSE)
  repeat {
    if (file.exists(file.path(current, "_quarto.yml"))) {
      return(current)
    }
    parent <- dirname(current)
    if (identical(parent, current)) {
      stop("Impossible de trouver la racine du projet contenant _quarto.yml.", call. = FALSE)
    }
    current <- parent
  }
}

ratio_if_possible <- function(numerator, denominator) {
  if_else(
    !is.na(numerator) & !is.na(denominator) & denominator > 0,
    numerator / denominator,
    NA_real_
  )
}

as_local_datetime <- function(x) {
  as.POSIXct(as.numeric(x), origin = "1970-01-01", tz = "America/Toronto")
}

root <- find_project_root()
raw_dir <- file.path(root, "data/raw/bixi")
processed_dir <- file.path(root, "data/processed/bixi")
dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(processed_dir, recursive = TRUE, showWarnings = FALSE)

access_date <- Sys.Date()
snapshot_downloaded_at <- Sys.time()
source_page <- "https://www.donneesquebec.ca/recherche/dataset/vmtl-bixi-etat-des-stations"
source_api <- "https://www.donneesquebec.ca/recherche/api/3/action/package_show?id=vmtl-bixi-etat-des-stations"
gbfs_discovery_url <- "https://gbfs.velobixi.com/gbfs/gbfs.json"

package_json_path <- file.path(raw_dir, "package_show_bixi.json")
gbfs_discovery_path <- file.path(raw_dir, "gbfs.json")
station_information_path <- file.path(raw_dir, "station_information.json")
station_status_path <- file.path(raw_dir, "station_status.json")

download_source(source_api, package_json_path, mode = "wb", quiet = TRUE)
download_source(gbfs_discovery_url, gbfs_discovery_path, mode = "wb", quiet = TRUE)

package <- fromJSON(package_json_path, flatten = TRUE)
if (!isTRUE(package$success)) {
  stop("L'API CKAN n'a pas retourné success = TRUE.", call. = FALSE)
}

resources <- package$result$resources |>
  transmute(
    resource_id = id,
    resource_name = name,
    format = toupper(format),
    url = url,
    last_modified = as.character(last_modified),
    metadata_modified = as.character(metadata_modified),
    size = suppressWarnings(as.numeric(size))
  )

gbfs_discovery <- fromJSON(gbfs_discovery_path, flatten = TRUE)
feeds_fr <- gbfs_discovery$data$fr$feeds |>
  mutate(language = "fr")
feeds_en <- gbfs_discovery$data$en$feeds |>
  mutate(language = "en")

feeds <- bind_rows(feeds_fr, feeds_en) |>
  select(language, feed_name = name, url) |>
  arrange(language, feed_name)

station_information_url <- feeds |>
  filter(language == "fr", feed_name == "station_information") |>
  pull(url)
station_status_url <- feeds |>
  filter(language == "fr", feed_name == "station_status") |>
  pull(url)

if (length(station_information_url) != 1L || length(station_status_url) != 1L) {
  stop("Les flux GBFS requis sont absents du fichier de découverte.", call. = FALSE)
}

download_source(station_information_url, station_information_path, mode = "wb", quiet = TRUE)
download_source(station_status_url, station_status_path, mode = "wb", quiet = TRUE)

station_information_json <- fromJSON(station_information_path, flatten = TRUE)
station_status_json <- fromJSON(station_status_path, flatten = TRUE)
snapshot_downloaded_at <- as.POSIXct(
  jsonlite::read_json(paste0(station_status_path, ".source.json"))$acquired_at_utc,
  format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"
)

station_information <- station_information_json$data$stations
station_status <- station_status_json$data$stations

required_information_columns <- c(
  "station_id",
  "name",
  "short_name",
  "lat",
  "lon",
  "capacity"
)
required_status_columns <- c(
  "station_id",
  "num_bikes_available",
  "num_ebikes_available",
  "num_bikes_disabled",
  "num_docks_available",
  "num_docks_disabled",
  "is_installed",
  "is_renting",
  "is_returning",
  "last_reported"
)

missing_information_columns <- setdiff(required_information_columns, names(station_information))
missing_status_columns <- setdiff(required_status_columns, names(station_status))
if (length(missing_information_columns) > 0L || length(missing_status_columns) > 0L) {
  stop(
    "Champs GBFS absents : ",
    paste(c(missing_information_columns, missing_status_columns), collapse = ", "),
    call. = FALSE
  )
}

stations <- station_information |>
  select(all_of(required_information_columns)) |>
  left_join(
    station_status |> select(all_of(required_status_columns)),
    by = "station_id"
  ) |>
  mutate(
    across(
      c(
        capacity,
        num_bikes_available,
        num_ebikes_available,
        num_bikes_disabled,
        num_docks_available,
        num_docks_disabled,
        is_installed,
        is_renting,
        is_returning,
        last_reported
      ),
      as.numeric
    ),
    num_bikes_classic_available = num_bikes_available - num_ebikes_available,
    taux_occupation = ratio_if_possible(num_bikes_available, capacity),
    taux_bornes_libres = ratio_if_possible(num_docks_available, capacity),
    part_velos_electriques = ratio_if_possible(num_ebikes_available, num_bikes_available),
    last_reported_datetime = as_local_datetime(last_reported),
    etat_operationnel = case_when(
      is_installed == 1 & is_renting == 1 & is_returning == 1 ~ "Disponible pour location et retour",
      is_installed != 1 ~ "Non installée",
      is_renting != 1 & is_returning != 1 ~ "Location et retour indisponibles",
      is_renting != 1 ~ "Location indisponible",
      is_returning != 1 ~ "Retour indisponible",
      TRUE ~ "État à vérifier"
    ),
    coordonnees_valides = !is.na(lat) & !is.na(lon) & !(lat == 0 & lon == 0),
    groupe_capacite = case_when(
      is.na(capacity) ~ "Capacité manquante",
      capacity <= 15 ~ "Petite station, 15 bornes ou moins",
      capacity <= 25 ~ "Station moyenne, 16 à 25 bornes",
      capacity <= 35 ~ "Grande station, 26 à 35 bornes",
      TRUE ~ "Très grande station, 36 bornes ou plus"
    ),
    station_information_updated_at = as_local_datetime(station_information_json$last_updated),
    station_status_updated_at = as_local_datetime(station_status_json$last_updated),
    snapshot_downloaded_at = snapshot_downloaded_at,
    source_station_information_url = station_information_url,
    source_station_status_url = station_status_url,
    access_date = access_date
  ) |>
  select(
    station_id,
    name,
    short_name,
    lat,
    lon,
    capacity,
    groupe_capacite,
    num_bikes_available,
    num_bikes_classic_available,
    num_ebikes_available,
    num_bikes_disabled,
    num_docks_available,
    num_docks_disabled,
    taux_occupation,
    taux_bornes_libres,
    part_velos_electriques,
    is_installed,
    is_renting,
    is_returning,
    etat_operationnel,
    coordonnees_valides,
    last_reported_datetime,
    station_information_updated_at,
    station_status_updated_at,
    snapshot_downloaded_at,
    source_station_information_url,
    source_station_status_url,
    access_date
  ) |>
  arrange(name, station_id)

summary_by_capacity <- stations |>
  group_by(groupe_capacite) |>
  summarise(
    n_stations = n(),
    capacity_total = sum(capacity, na.rm = TRUE),
    bikes_available_total = sum(num_bikes_available, na.rm = TRUE),
    ebikes_available_total = sum(num_ebikes_available, na.rm = TRUE),
    docks_available_total = sum(num_docks_available, na.rm = TRUE),
    median_taux_occupation = round(median(taux_occupation, na.rm = TRUE), 3),
    pct_stations = round(100 * n() / nrow(stations), 1),
    .groups = "drop"
  ) |>
  arrange(desc(capacity_total), groupe_capacite)

summary_by_operation <- stations |>
  count(etat_operationnel, name = "n_stations") |>
  mutate(pct_stations = round(100 * n_stations / sum(n_stations), 1)) |>
  arrange(desc(n_stations), etat_operationnel)

availability_extremes <- stations |>
  filter(
    !is.na(taux_occupation),
    capacity > 0,
    coordonnees_valides,
    etat_operationnel == "Disponible pour location et retour"
  ) |>
  mutate(
    classe_disponibilite = case_when(
      taux_occupation <= 0.1 ~ "Très peu de vélos disponibles",
      taux_occupation >= 0.9 ~ "Station presque pleine",
      TRUE ~ "Disponibilité intermédiaire"
    )
  ) |>
  filter(classe_disponibilite != "Disponibilité intermédiaire") |>
  arrange(taux_occupation, name) |>
  select(
    station_id,
    name,
    capacity,
    num_bikes_available,
    num_ebikes_available,
    num_docks_available,
    taux_occupation,
    classe_disponibilite,
    etat_operationnel,
    lat,
    lon
  )

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

valid_ratios <- stations |>
  filter(!is.na(capacity), capacity > 0)

dataset_summary <- tibble::tibble(
  metric = c(
    "source_page",
    "source_api",
    "gbfs_discovery_url",
    "station_information_url",
    "station_status_url",
    "access_date",
    "snapshot_downloaded_at",
    "package_id",
    "metadata_modified",
    "resource_last_modified",
    "resource_metadata_modified",
    "license_title",
    "gbfs_discovery_last_updated",
    "gbfs_discovery_ttl",
    "station_information_last_updated",
    "station_information_ttl",
    "station_status_last_updated",
    "station_status_ttl",
    "n_resources_ckan",
    "n_feeds_fr",
    "n_rows_station_information",
    "n_columns_station_information",
    "n_rows_station_status",
    "n_columns_station_status",
    "n_rows_prepared",
    "n_columns_prepared",
    "n_stations_installed",
    "n_stations_renting",
    "n_stations_returning",
    "n_stations_full_service",
    "n_valid_coordinates",
    "n_zero_coordinates",
    "capacity_total",
    "median_capacity",
    "bikes_available_total",
    "classic_bikes_available_total",
    "ebikes_available_total",
    "docks_available_total",
    "bikes_disabled_total",
    "docks_disabled_total",
    "median_taux_occupation",
    "median_part_velos_electriques",
    "pct_stations_taux_under_25",
    "pct_stations_taux_over_75",
    "n_stations_empty",
    "n_stations_full"
  ),
  value = c(
    source_page,
    source_api,
    gbfs_discovery_url,
    station_information_url,
    station_status_url,
    as.character(access_date),
    format(snapshot_downloaded_at, "%Y-%m-%d %H:%M:%S %Z"),
    package$result$id,
    as.character(package$result$metadata_modified),
    as.character(resources$last_modified[resources$url == gbfs_discovery_url]),
    as.character(resources$metadata_modified[resources$url == gbfs_discovery_url]),
    as.character(package$result$license_title),
    as.character(as_local_datetime(gbfs_discovery$last_updated)),
    as.character(gbfs_discovery$ttl),
    as.character(as_local_datetime(station_information_json$last_updated)),
    as.character(station_information_json$ttl),
    as.character(as_local_datetime(station_status_json$last_updated)),
    as.character(station_status_json$ttl),
    as.character(nrow(resources)),
    as.character(nrow(feeds_fr)),
    as.character(nrow(station_information)),
    as.character(ncol(station_information)),
    as.character(nrow(station_status)),
    as.character(ncol(station_status)),
    as.character(nrow(stations)),
    as.character(ncol(stations)),
    as.character(sum(stations$is_installed == 1, na.rm = TRUE)),
    as.character(sum(stations$is_renting == 1, na.rm = TRUE)),
    as.character(sum(stations$is_returning == 1, na.rm = TRUE)),
    as.character(sum(stations$etat_operationnel == "Disponible pour location et retour", na.rm = TRUE)),
    as.character(sum(stations$coordonnees_valides, na.rm = TRUE)),
    as.character(sum(stations$lat == 0 & stations$lon == 0, na.rm = TRUE)),
    as.character(sum(stations$capacity, na.rm = TRUE)),
    as.character(median(stations$capacity, na.rm = TRUE)),
    as.character(sum(stations$num_bikes_available, na.rm = TRUE)),
    as.character(sum(stations$num_bikes_classic_available, na.rm = TRUE)),
    as.character(sum(stations$num_ebikes_available, na.rm = TRUE)),
    as.character(sum(stations$num_docks_available, na.rm = TRUE)),
    as.character(sum(stations$num_bikes_disabled, na.rm = TRUE)),
    as.character(sum(stations$num_docks_disabled, na.rm = TRUE)),
    as.character(round(median(valid_ratios$taux_occupation, na.rm = TRUE), 3)),
    as.character(round(median(valid_ratios$part_velos_electriques, na.rm = TRUE), 3)),
    as.character(round(100 * mean(valid_ratios$taux_occupation < 0.25, na.rm = TRUE), 1)),
    as.character(round(100 * mean(valid_ratios$taux_occupation > 0.75, na.rm = TRUE), 1)),
    as.character(sum(stations$num_bikes_available == 0, na.rm = TRUE)),
    as.character(sum(stations$num_docks_available == 0, na.rm = TRUE))
  )
)

stopifnot(
  nrow(resources) == 1,
  nrow(feeds_fr) >= 2,
  nrow(station_information) > 1000,
  nrow(station_status) > 1000,
  n_distinct(station_information$station_id) == nrow(station_information),
  n_distinct(station_status$station_id) == nrow(station_status),
  nrow(stations) == nrow(station_information),
  ncol(stations) == 28,
  all(!is.na(stations$station_id)),
  all(!is.na(stations$lat)),
  all(!is.na(stations$lon))
)

write_csv(resources, file.path(processed_dir, "ressources_ckan_bixi.csv"))
write_csv(feeds, file.path(processed_dir, "flux_gbfs_bixi.csv"))
write_csv(stations, file.path(processed_dir, "stations_bixi_snapshot.csv"))
write_csv(summary_by_capacity, file.path(processed_dir, "resume_groupes_capacite_bixi.csv"))
write_csv(summary_by_operation, file.path(processed_dir, "resume_operation_bixi.csv"))
write_csv(availability_extremes, file.path(processed_dir, "stations_bixi_disponibilite_extreme.csv"))
write_csv(missing_summary, file.path(processed_dir, "valeurs_manquantes_bixi.csv"))
write_csv(dataset_summary, file.path(processed_dir, "resume_bixi_snapshot.csv"))

record_preparation("bixi")
