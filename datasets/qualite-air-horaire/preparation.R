# Préparation : Qualité de l'air au Québec
# Source officielle : Données Québec, paquet CKAN a80757bd-d442-4d3d-9269-11628330b727.

library(dplyr)
library(jsonlite)
library(readr)
library(stringr)
library(tidyr)

raw_dir <- "data/raw/qualite-air-horaire"
processed_dir <- "data/processed/qualite-air-horaire"
dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(processed_dir, recursive = TRUE, showWarnings = FALSE)

access_date <- "2026-06-21"
source_page <- "https://www.donneesquebec.ca/recherche/dataset/rsqaq-donnees-horaires-continues"
package_api <- "https://www.donneesquebec.ca/recherche/api/3/action/package_show?id=rsqaq-donnees-horaires-continues"
source_year <- 2025L

package_json_path <- file.path(raw_dir, "package_show_rsqaq_donnees_horaires_continues.json")
raw_csv_path <- file.path(raw_dir, "rsqaq_continues_horaires_2025.csv")

download.file(package_api, package_json_path, mode = "wb", quiet = TRUE)
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
    last_modified = as.character(last_modified),
    size = suppressWarnings(as.numeric(size))
  )

resource_2025 <- resources |>
  filter(resource_name == "RSQAQ - Données continues horaires 2025")

if (nrow(resource_2025) != 1L) {
  stop("La ressource 2025 n'a pas été trouvée de façon unique.", call. = FALSE)
}

download.file(resource_2025$url[[1]], raw_csv_path, mode = "wb", quiet = TRUE)

source_data <- read_csv(
  raw_csv_path,
  show_col_types = FALSE,
  col_types = cols(Date_Heure = col_character(), .default = col_guess()),
  locale = locale(encoding = "UTF-8")
)

expected_columns <- c(
  "Station",
  "Date_Heure",
  "BC_880nm",
  "CO",
  "H2S",
  "NO2-CAPS",
  "NO2",
  "NO-CAPS",
  "NO",
  "O3",
  "PM0.1-CPC",
  "PM2.5-T640",
  "SO2"
)

missing_columns <- setdiff(expected_columns, names(source_data))
if (length(missing_columns) > 0L) {
  stop(
    "Colonnes manquantes dans le CSV 2025 : ",
    paste(missing_columns, collapse = ", "),
    call. = FALSE
  )
}

pollutant_columns <- setdiff(names(source_data), c("Station", "Date_Heure"))

pollutant_labels <- c(
  "BC_880nm" = "BC 880 nm",
  "CO" = "CO",
  "H2S" = "H2S",
  "NO2-CAPS" = "NO2-CAPS",
  "NO2" = "NO2",
  "NO-CAPS" = "NO-CAPS",
  "NO" = "NO",
  "O3" = "O3",
  "PM0.1-CPC" = "PM0.1-CPC",
  "PM2.5-T640" = "PM2.5-T640",
  "SO2" = "SO2"
)

station_fields <- source_data |>
  distinct(Station) |>
  mutate(
    station_id = str_extract(Station, "^\\d+"),
    station_name = str_squish(str_remove(Station, "^\\d+\\s*-\\s*"))
  )

source_with_station <- source_data |>
  left_join(station_fields, by = "Station") |>
  mutate(
    date_heure = as.POSIXct(Date_Heure, tz = "UTC"),
    date = as.Date(date_heure),
    year = as.integer(format(date_heure, "%Y")),
    month = as.integer(format(date_heure, "%m")),
    hour = as.integer(format(date_heure, "%H"))
  )

long_measurements <- source_with_station |>
  pivot_longer(
    cols = all_of(pollutant_columns),
    names_to = "contaminant_source",
    values_to = "concentration"
  ) |>
  filter(!is.na(concentration)) |>
  mutate(
    contaminant = unname(pollutant_labels[contaminant_source]),
    source_year = source_year,
    access_date = access_date
  ) |>
  select(
    source_year,
    station_id,
    station_name,
    date_heure,
    date,
    year,
    month,
    hour,
    contaminant_source,
    contaminant,
    concentration,
    access_date
  )

daily_summary <- long_measurements |>
  group_by(date, station_id, station_name, contaminant_source, contaminant) |>
  summarise(
    n_heures_valides = n(),
    moyenne = mean(concentration, na.rm = TRUE),
    mediane = median(concentration, na.rm = TRUE),
    p95 = as.numeric(quantile(concentration, 0.95, na.rm = TRUE)),
    maximum = max(concentration, na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(
    source_year = source_year,
    access_date = access_date,
    .before = 1
  ) |>
  arrange(date, station_id, contaminant_source)

contaminant_summary <- long_measurements |>
  group_by(contaminant_source, contaminant) |>
  summarise(
    n_mesures = n(),
    n_stations = n_distinct(station_id),
    premiere_mesure = min(date_heure, na.rm = TRUE),
    derniere_mesure = max(date_heure, na.rm = TRUE),
    moyenne = mean(concentration, na.rm = TRUE),
    mediane = median(concentration, na.rm = TRUE),
    p95 = as.numeric(quantile(concentration, 0.95, na.rm = TRUE)),
    maximum = max(concentration, na.rm = TRUE),
    .groups = "drop"
  ) |>
  arrange(desc(n_mesures))

station_summary <- long_measurements |>
  group_by(station_id, station_name) |>
  summarise(
    n_mesures = n(),
    n_contaminants = n_distinct(contaminant_source),
    premiere_mesure = min(date_heure, na.rm = TRUE),
    derniere_mesure = max(date_heure, na.rm = TRUE),
    .groups = "drop"
  ) |>
  arrange(station_id)

missing_summary <- source_data |>
  summarise(across(all_of(pollutant_columns), ~ sum(is.na(.x)))) |>
  pivot_longer(
    cols = everything(),
    names_to = "contaminant_source",
    values_to = "n_missing"
  ) |>
  mutate(
    contaminant = unname(pollutant_labels[contaminant_source]),
    n_rows = nrow(source_data),
    n_observed = n_rows - n_missing,
    pct_observed = round(100 * n_observed / n_rows, 2)
  ) |>
  arrange(desc(n_observed))

top_pm25_days <- daily_summary |>
  filter(contaminant_source == "PM2.5-T640", n_heures_valides >= 18) |>
  arrange(desc(moyenne)) |>
  slice_head(n = 25)

dataset_summary <- tibble::tibble(
  metric = c(
    "source_page",
    "package_api",
    "access_date",
    "package_id",
    "package_title",
    "organization",
    "license",
    "metadata_modified",
    "source_year",
    "resource_id",
    "resource_last_modified",
    "resource_size",
    "n_resources_ckan",
    "raw_rows",
    "raw_columns",
    "n_stations",
    "n_contaminants",
    "n_non_missing_measurements",
    "daily_summary_rows",
    "first_datetime",
    "last_datetime",
    "pm25_measurements",
    "pm25_stations",
    "pm25_max_hourly",
    "pm25_highest_daily_mean"
  ),
  value = c(
    source_page,
    package_api,
    access_date,
    package$result$id,
    package$result$title,
    package$result$organization$title,
    package$result$license_title,
    package$result$metadata_modified,
    as.character(source_year),
    resource_2025$resource_id[[1]],
    resource_2025$last_modified[[1]],
    as.character(resource_2025$size[[1]]),
    as.character(nrow(resources)),
    as.character(nrow(source_data)),
    as.character(ncol(source_data)),
    as.character(n_distinct(source_with_station$station_id)),
    as.character(length(pollutant_columns)),
    as.character(nrow(long_measurements)),
    as.character(nrow(daily_summary)),
    as.character(min(long_measurements$date_heure, na.rm = TRUE)),
    as.character(max(long_measurements$date_heure, na.rm = TRUE)),
    as.character(contaminant_summary$n_mesures[contaminant_summary$contaminant_source == "PM2.5-T640"]),
    as.character(contaminant_summary$n_stations[contaminant_summary$contaminant_source == "PM2.5-T640"]),
    as.character(contaminant_summary$maximum[contaminant_summary$contaminant_source == "PM2.5-T640"]),
    as.character(top_pm25_days$moyenne[[1]])
  )
)

stopifnot(
  nrow(resources) == 51L,
  nrow(source_data) == 457686L,
  ncol(source_data) == 13L,
  n_distinct(source_with_station$station_id) == 54L,
  length(pollutant_columns) == 11L,
  nrow(long_measurements) == 1549609L,
  nrow(daily_summary) == 65306L,
  all(source_with_station$year == 2025L),
  contaminant_summary$n_mesures[contaminant_summary$contaminant_source == "PM2.5-T640"] == 436243L,
  contaminant_summary$n_stations[contaminant_summary$contaminant_source == "PM2.5-T640"] == 52L,
  top_pm25_days$station_name[[1]] == "Radisson",
  as.character(top_pm25_days$date[[1]]) == "2025-06-04"
)

write_csv(daily_summary, file.path(processed_dir, "resume_journalier_contaminants_2025.csv"))
write_csv(contaminant_summary, file.path(processed_dir, "resume_contaminants_2025.csv"))
write_csv(station_summary, file.path(processed_dir, "resume_stations_2025.csv"))
write_csv(missing_summary, file.path(processed_dir, "valeurs_manquantes_contaminants_2025.csv"))
write_csv(top_pm25_days, file.path(processed_dir, "episodes_pm25_2025.csv"))
write_csv(resources, file.path(processed_dir, "ressources_rsqaq_horaires_continues.csv"))
write_csv(dataset_summary, file.path(processed_dir, "resume_qualite_air_horaire.csv"))

message("Source : ", source_page)
message("API CKAN : ", package_api)
message("Ressource préparée : ", resource_2025$resource_name[[1]])
message("Fichier brut : ", raw_csv_path)
message("Résumé journalier : ", file.path(processed_dir, "resume_journalier_contaminants_2025.csv"))
message("Lignes brutes : ", nrow(source_data))
message("Mesures non manquantes : ", nrow(long_measurements))
message("Stations : ", n_distinct(source_with_station$station_id))
