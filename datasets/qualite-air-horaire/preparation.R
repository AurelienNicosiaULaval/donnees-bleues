source("R/utils_downloads.R")
# Préparation : Qualité de l'air au Québec
# Source officielle : Données Québec, paquet CKAN a80757bd-d442-4d3d-9269-11628330b727.

library(dplyr)
library(jsonlite)
library(readr)
library(stringr)
library(tidyr)
source("R/utils_data_checks.R")

raw_dir <- "data/raw/qualite-air-horaire"
processed_dir <- "data/processed/qualite-air-horaire"
dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(processed_dir, recursive = TRUE, showWarnings = FALSE)

access_date <- as.character(Sys.Date())
source_page <- "https://www.donneesquebec.ca/recherche/dataset/rsqaq-donnees-horaires-continues"
package_api <- "https://www.donneesquebec.ca/recherche/api/3/action/package_show?id=rsqaq-donnees-horaires-continues"
source_year <- 2025L

package_json_path <- file.path(raw_dir, "package_show_rsqaq_donnees_horaires_continues.json")
raw_csv_path <- file.path(raw_dir, "rsqaq_continues_horaires_2025.csv")

download_source(package_api, package_json_path, mode = "wb", quiet = TRUE)
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

download_source(resource_2025$url[[1]], raw_csv_path, mode = "wb", quiet = TRUE)

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
if (!setequal(pollutant_columns, setdiff(expected_columns, c("Station", "Date_Heure")))) {
  stop("La liste des contaminants a changé; vérifier leurs unités et leur documentation.", call. = FALSE)
}
validate_unique_key(source_data, c("Station", "Date_Heure"), "mesures horaires")

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

# Unités et horodatage documentés dans la méthodologie du jeu officiel RSQAQ.
# Chaque heure publiée marque la FIN de l'intervalle, en HNE (UTC-5 fixe).
pollutant_units <- c(
  "BC_880nm" = "µg/m³", "CO" = "ppm", "H2S" = "ppb",
  "NO2-CAPS" = "ppb", "NO2" = "ppb", "NO-CAPS" = "ppb",
  "NO" = "ppb", "O3" = "ppb", "PM0.1-CPC" = "k part/cm³",
  "PM2.5-T640" = "µg/m³", "SO2" = "ppb"
)
stopifnot(setequal(names(pollutant_units), pollutant_columns))

station_fields <- source_data |>
  distinct(Station) |>
  mutate(
    station_id = str_extract(Station, "^\\d+"),
    station_name = str_squish(str_remove(Station, "^\\d+\\s*-\\s*"))
  )

source_with_station <- source_data |>
  left_join(station_fields, by = "Station") |>
  mutate(
    date_heure = parse_air_hour_end(Date_Heure),
    date = air_calendar_day(date_heure),
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
  filter(!is.na(concentration), format(date, "%Y") == as.character(source_year)) |>
  mutate(
    contaminant = unname(pollutant_labels[contaminant_source]),
    unite = unname(pollutant_units[contaminant_source]),
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
    unite,
    concentration,
    access_date
  )

daily_summary <- long_measurements |>
  group_by(date, station_id, station_name, contaminant_source, contaminant, unite) |>
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
  group_by(contaminant_source, contaminant, unite) |>
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
    unite = unname(pollutant_units[contaminant_source]),
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
    "hours_timezone",
    "daily_interval_convention",
    "non_missing_measurements_outside_calendar_year",
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
    "HNE (UTC-5 fixe)",
    "Date de début de l’intervalle horaire; seuls les jours de 2025 sont retenus",
    as.character(sum(!is.na(as.matrix(source_data[pollutant_columns]))) - nrow(long_measurements)),
    as.character(min(long_measurements$date_heure, na.rm = TRUE)),
    as.character(max(long_measurements$date_heure, na.rm = TRUE)),
    as.character(contaminant_summary$n_mesures[contaminant_summary$contaminant_source == "PM2.5-T640"]),
    as.character(contaminant_summary$n_stations[contaminant_summary$contaminant_source == "PM2.5-T640"]),
    as.character(contaminant_summary$maximum[contaminant_summary$contaminant_source == "PM2.5-T640"]),
    as.character(top_pm25_days$moyenne[[1]])
  )
)

validate_unique_key(daily_summary, c("date", "station_id", "contaminant_source"), "résumés journaliers")
stopifnot(
  !anyNA(source_with_station$date_heure),
  all(source_with_station$year == source_year),
  nrow(long_measurements) > 0L,
  all(is.finite(long_measurements$concentration)),
  all(daily_summary$n_heures_valides >= 1L & daily_summary$n_heures_valides <= 24L),
  sum(daily_summary$n_heures_valides) == nrow(long_measurements),
  sum(contaminant_summary$n_mesures) == nrow(long_measurements),
  all(daily_summary$mediane <= daily_summary$maximum),
  all(daily_summary$p95 <= daily_summary$maximum)
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

record_preparation("qualite-air-horaire")
