source("R/utils_downloads.R")
# Préparation : GTFS du Réseau de transport de la Capitale
# Source officielle : Données Québec, paquet CKAN a6ad0f52-9699-43ed-9907-791472badc19.

library(dplyr)
library(jsonlite)
library(readr)
library(stringr)
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

count_gtfs_rows <- function(path) {
  as.numeric(length(read_lines(path, progress = FALSE)) - 1)
}

parse_gtfs_date <- function(x) {
  as.Date(as.character(x), format = "%Y%m%d")
}

route_type_label <- function(x) {
  dplyr::case_when(
    x == 0L ~ "Tramway ou métro léger",
    x == 1L ~ "Métro",
    x == 2L ~ "Train",
    x == 3L ~ "Bus",
    x == 4L ~ "Traversier",
    x == 5L ~ "Cable tram",
    x == 6L ~ "Téléphérique",
    x == 7L ~ "Funiculaire",
    TRUE ~ "Autre ou non documenté"
  )
}

wheelchair_label <- function(x) {
  dplyr::case_when(
    x == 0L ~ "Information non disponible",
    x == 1L ~ "Accessible selon le codage GTFS",
    x == 2L ~ "Non accessible selon le codage GTFS",
    TRUE ~ "Code non documenté"
  )
}

root <- find_project_root()
raw_dir <- file.path(root, "data/raw/transport-collectif-gtfs")
processed_dir <- file.path(root, "data/processed/transport-collectif-gtfs")
dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(processed_dir, recursive = TRUE, showWarnings = FALSE)

access_date <- Sys.Date()
source_page <- "https://www.donneesquebec.ca/recherche/dataset/rtc-gtfs-arrets-et-les-parcours"
source_api <- "https://www.donneesquebec.ca/recherche/api/3/action/package_show?id=rtc-gtfs-arrets-et-les-parcours"
source_rtc_page <- "https://www.rtcquebec.ca/donnees-ouvertes"
gtfs_zip_url <- "https://cdn.rtcquebec.ca/Site_Internet/DonneesOuvertes/googletransit.zip"

package_json_path <- file.path(raw_dir, "package_show_rtc_gtfs.json")
zip_path <- file.path(raw_dir, "googletransit.zip")
unzip_dir <- file.path(raw_dir, "googletransit")

download_source(source_api, package_json_path, mode = "wb", quiet = TRUE)
download_source(gtfs_zip_url, zip_path, mode = "wb", quiet = TRUE)

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

unlink(unzip_dir, recursive = TRUE)
dir.create(unzip_dir, recursive = TRUE, showWarnings = FALSE)
unzip(zip_path, exdir = unzip_dir)

required_files <- c(
  "agency.txt",
  "stops.txt",
  "routes.txt",
  "trips.txt",
  "stop_times.txt",
  "calendar_dates.txt",
  "feed_info.txt"
)

zip_files <- unzip(zip_path, list = TRUE) |>
  as_tibble() |>
  mutate(
    file = Name,
    size_bytes = as.numeric(Length),
    modified_inside_zip = as.character(Date),
    n_rows = vapply(file.path(unzip_dir, Name), count_gtfs_rows, numeric(1))
  ) |>
  select(file, size_bytes, modified_inside_zip, n_rows)

missing_files <- setdiff(required_files, zip_files$file)
if (length(missing_files) > 0L) {
  stop("Fichiers GTFS requis absents : ", paste(missing_files, collapse = ", "), call. = FALSE)
}

agency <- read_csv(
  file.path(unzip_dir, "agency.txt"),
  col_types = cols(.default = col_character()),
  show_col_types = FALSE
)

feed_info <- read_csv(
  file.path(unzip_dir, "feed_info.txt"),
  col_types = cols(.default = col_character()),
  show_col_types = FALSE
)

stops_raw <- read_csv(
  file.path(unzip_dir, "stops.txt"),
  col_types = cols(
    .default = col_character(),
    stop_code = col_integer(),
    stop_lat = col_double(),
    stop_lon = col_double(),
    wheelchair_boarding = col_integer()
  ),
  show_col_types = FALSE
)

routes_raw <- read_csv(
  file.path(unzip_dir, "routes.txt"),
  col_types = cols(
    .default = col_character(),
    route_type = col_integer()
  ),
  show_col_types = FALSE
)

trips_raw <- read_csv(
  file.path(unzip_dir, "trips.txt"),
  col_types = cols(
    .default = col_character(),
    direction_id = col_integer(),
    wheelchair_accessible = col_integer()
  ),
  show_col_types = FALSE
)

calendar_dates <- read_csv(
  file.path(unzip_dir, "calendar_dates.txt"),
  col_types = cols(
    service_id = col_character(),
    date = col_character(),
    exception_type = col_integer()
  ),
  show_col_types = FALSE
) |>
  mutate(service_date = parse_gtfs_date(date)) |>
  select(service_id, service_date, exception_type)

stops <- stops_raw |>
  transmute(
    stop_id,
    stop_code,
    stop_name,
    stop_description = stop_desc,
    latitude = stop_lat,
    longitude = stop_lon,
    wheelchair_boarding,
    wheelchair_boarding_label = wheelchair_label(wheelchair_boarding),
    stop_url,
    source_zip_url = gtfs_zip_url,
    access_date
  ) |>
  arrange(stop_code, stop_id)

routes <- routes_raw |>
  transmute(
    route_id,
    agency_id,
    route_short_name,
    route_description = route_desc,
    route_type,
    route_type_label = route_type_label(route_type),
    route_url,
    route_color,
    route_text_color,
    source_zip_url = gtfs_zip_url,
    access_date
  ) |>
  arrange(route_short_name, route_id)

trips <- trips_raw |>
  transmute(
    route_id,
    service_id,
    shape_id,
    trip_id,
    trip_headsign,
    trip_short_name,
    direction_id,
    block_id,
    wheelchair_accessible,
    wheelchair_accessible_label = wheelchair_label(wheelchair_accessible),
    source_zip_url = gtfs_zip_url,
    access_date
  ) |>
  arrange(route_id, service_id, trip_id)

route_summary <- trips |>
  left_join(
    routes |> select(route_id, route_short_name, route_description, route_type_label),
    by = "route_id"
  ) |>
  group_by(route_id, route_short_name, route_description, route_type_label) |>
  summarise(
    n_trips = n(),
    n_services = n_distinct(service_id),
    n_shapes = n_distinct(shape_id),
    n_directions = n_distinct(direction_id, na.rm = TRUE),
    n_trips_accessibles = sum(wheelchair_accessible == 1L, na.rm = TRUE),
    n_trips_accessibilite_inconnue = sum(wheelchair_accessible == 0L, na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(
    pct_trips_accessibles = round(100 * n_trips_accessibles / n_trips, 1)
  ) |>
  arrange(desc(n_trips), route_short_name)

accessibility_summary <- bind_rows(
  stops |>
    count(
      table = "stops",
      code = wheelchair_boarding,
      interpretation = wheelchair_boarding_label,
      name = "n_rows"
    ),
  trips |>
    count(
      table = "trips",
      code = wheelchair_accessible,
      interpretation = wheelchair_accessible_label,
      name = "n_rows"
    )
) |>
  group_by(table) |>
  mutate(pct_rows = round(100 * n_rows / sum(n_rows), 1)) |>
  ungroup() |>
  arrange(table, code)

service_summary <- calendar_dates |>
  summarise(
    first_service_date = min(service_date, na.rm = TRUE),
    last_service_date = max(service_date, na.rm = TRUE),
    n_service_dates = n_distinct(service_date),
    n_service_ids = n_distinct(service_id),
    n_exception_type_1 = sum(exception_type == 1L, na.rm = TRUE),
    n_exception_type_2 = sum(exception_type == 2L, na.rm = TRUE)
  )

missing_summary <- bind_rows(
  stops |>
    summarise(across(everything(), ~ sum(is.na(.x)))) |>
    pivot_longer(everything(), names_to = "variable", values_to = "n_missing") |>
    mutate(table = "stops", n_rows = nrow(stops)),
  routes |>
    summarise(across(everything(), ~ sum(is.na(.x)))) |>
    pivot_longer(everything(), names_to = "variable", values_to = "n_missing") |>
    mutate(table = "routes", n_rows = nrow(routes)),
  trips |>
    summarise(across(everything(), ~ sum(is.na(.x)))) |>
    pivot_longer(everything(), names_to = "variable", values_to = "n_missing") |>
    mutate(table = "trips", n_rows = nrow(trips))
) |>
  mutate(pct_missing = round(100 * n_missing / n_rows, 2)) |>
  select(table, variable, n_rows, n_missing, pct_missing) |>
  arrange(desc(n_missing), table, variable)

dataset_summary <- tibble::tibble(
  metric = c(
    "source_page",
    "source_api",
    "source_rtc_page",
    "gtfs_zip_url",
    "access_date",
    "package_id",
    "package_metadata_modified",
    "license_title",
    "n_resources_ckan",
    "n_files_in_zip",
    "n_stops",
    "n_routes",
    "n_trips",
    "n_stop_times",
    "n_shapes",
    "n_transfers",
    "first_service_date",
    "last_service_date",
    "n_service_dates",
    "n_service_ids",
    "n_accessible_stops_code_1",
    "n_unknown_accessibility_stops_code_0",
    "n_accessible_trips_code_1",
    "n_unknown_accessibility_trips_code_0"
  ),
  value = c(
    source_page,
    source_api,
    source_rtc_page,
    gtfs_zip_url,
    as.character(access_date),
    package$result$id,
    as.character(package$result$metadata_modified),
    as.character(package$result$license_title),
    as.character(nrow(resources)),
    as.character(nrow(zip_files)),
    as.character(nrow(stops)),
    as.character(nrow(routes)),
    as.character(nrow(trips)),
    as.character(zip_files$n_rows[zip_files$file == "stop_times.txt"]),
    as.character(zip_files$n_rows[zip_files$file == "shapes.txt"]),
    as.character(zip_files$n_rows[zip_files$file == "transfers.txt"]),
    as.character(service_summary$first_service_date),
    as.character(service_summary$last_service_date),
    as.character(service_summary$n_service_dates),
    as.character(service_summary$n_service_ids),
    as.character(sum(stops$wheelchair_boarding == 1L, na.rm = TRUE)),
    as.character(sum(stops$wheelchair_boarding == 0L, na.rm = TRUE)),
    as.character(sum(trips$wheelchair_accessible == 1L, na.rm = TRUE)),
    as.character(sum(trips$wheelchair_accessible == 0L, na.rm = TRUE))
  )
)

stopifnot(
  nrow(resources) == 2,
  all(required_files %in% zip_files$file),
  nrow(agency) >= 1,
  nrow(feed_info) == 1,
  nrow(stops) > 1000,
  nrow(routes) > 50,
  nrow(trips) > 10000,
  zip_files$n_rows[zip_files$file == "stop_times.txt"] > nrow(trips),
  all(!is.na(stops$latitude)),
  all(!is.na(stops$longitude)),
  all(!is.na(routes$route_type)),
  all(!is.na(calendar_dates$service_date))
)

write_csv(resources, file.path(processed_dir, "ressources_ckan_rtc_gtfs.csv"))
write_csv(zip_files, file.path(processed_dir, "inventaire_fichiers_gtfs_rtc.csv"))
write_csv(stops, file.path(processed_dir, "arrets_gtfs_rtc.csv"))
write_csv(routes, file.path(processed_dir, "parcours_gtfs_rtc.csv"))
write_csv(trips, file.path(processed_dir, "trajets_gtfs_rtc.csv"))
write_csv(route_summary, file.path(processed_dir, "resume_parcours_gtfs_rtc.csv"))
write_csv(accessibility_summary, file.path(processed_dir, "resume_accessibilite_gtfs_rtc.csv"))
write_csv(service_summary, file.path(processed_dir, "resume_services_gtfs_rtc.csv"))
write_csv(missing_summary, file.path(processed_dir, "valeurs_manquantes_gtfs_rtc.csv"))
write_csv(dataset_summary, file.path(processed_dir, "resume_gtfs_rtc.csv"))

record_preparation("transport-collectif-gtfs")
