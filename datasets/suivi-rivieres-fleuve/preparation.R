source("R/utils_downloads.R")
# Préparer le suivi physicochimique et bactériologique des rivières et du fleuve.
# Source officielle : https://www.donneesquebec.ca/recherche/dataset/suivi-physicochimique-des-rivieres-et-du-fleuve

library(curl)
library(dplyr)
library(jsonlite)
library(readr)
library(tibble)
library(tidyr)

dataset_id <- "suivi-rivieres-fleuve"
api_url <- "https://www.donneesquebec.ca/recherche/api/3/action/package_show?id=suivi-physicochimique-des-rivieres-et-du-fleuve"
source_url <- "https://www.donneesquebec.ca/recherche/dataset/suivi-physicochimique-des-rivieres-et-du-fleuve"
raw_dir <- file.path("data", "raw", dataset_id)
processed_dir <- file.path("data", "processed", dataset_id)
zip_path <- file.path(raw_dir, "IQBP_csv.zip")
extract_dir <- file.path(raw_dir, "IQBP_csv")

dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(processed_dir, recursive = TRUE, showWarnings = FALSE)

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
  tmp <- "data/raw/suivi-rivieres-fleuve/package_show.json"
  download_source(url, tmp, quiet = TRUE, handle = curl::new_handle(useragent = "Mozilla/5.0"))
  jsonlite::fromJSON(tmp, simplifyVector = FALSE)
}

write_processed_csv <- function(data, filename) {
  readr::write_csv(data, file.path(processed_dir, filename), na = "")
}

ckan <- read_ckan_package(api_url)
stopifnot(isTRUE(ckan$success))

package <- ckan$result
resources <- package$resources
resources_tbl <- bind_rows(lapply(seq_along(resources), function(i) {
  resource <- resources[[i]]
  tibble(
    resource_order = i,
    resource_id = pluck_text(resource, "id"),
    resource_name = pluck_text(resource, "name"),
    resource_description = pluck_text(resource, "description"),
    resource_format = pluck_text(resource, "format"),
    resource_url = pluck_text(resource, "url"),
    resource_last_modified = pluck_text(resource, "last_modified"),
    resource_metadata_modified = pluck_text(resource, "metadata_modified"),
    resource_size = pluck_number(resource, "size")
  )
}))

csv_resource <- resources_tbl |>
  filter(resource_format == "CSV") |>
  slice(1)

stopifnot(nrow(csv_resource) == 1)
download_source(csv_resource$resource_url, zip_path, quiet = TRUE)

if (dir.exists(extract_dir)) {
  unlink(extract_dir, recursive = TRUE)
}
dir.create(extract_dir, recursive = TRUE, showWarnings = FALSE)
unzip(zip_path, exdir = extract_dir)

stations_raw <- read_delim(
  file.path(extract_dir, "stations_p.csv"),
  delim = ";",
  show_col_types = FALSE
) |>
  rename_with(tolower)

aires_raw <- read_delim(
  file.path(extract_dir, "ad_s.csv"),
  delim = ";",
  show_col_types = FALSE
) |>
  rename_with(tolower)

stations <- stations_raw |>
  transmute(
    no_bqma,
    hydronyme,
    description,
    type_station,
    type_suivi,
    annee,
    n_echant,
    iqbp_med,
    ptot_med_mgl,
    ntot_med_mgl,
    nox_med_mgl,
    chla_med_ugl,
    cf_med_ufc,
    latitude,
    longitude,
    bv_n1m,
    bv_n2m,
    zgiebv,
    zgiesl
  )

aires_drainage <- aires_raw |>
  transmute(
    no_bqma,
    superf_qc_km2,
    superf_tot_km2,
    frontiere,
    pc_foret,
    pc_agricole,
    pc_anthropique,
    pc_aquatique,
    pc_humide,
    pc_coupe_regen,
    pc_sol_nu,
    pc_non_classe,
    annee_utilisation_territoire = annee_ut
  )

stations_aires <- stations |>
  left_join(aires_drainage, by = "no_bqma")

indicator_columns <- c(
  "iqbp_med",
  "ptot_med_mgl",
  "ntot_med_mgl",
  "nox_med_mgl",
  "chla_med_ugl",
  "cf_med_ufc"
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
  csv_resource_id = csv_resource$resource_id,
  csv_resource_last_modified = csv_resource$resource_last_modified,
  csv_resource_metadata_modified = csv_resource$resource_metadata_modified,
  csv_resource_size = csv_resource$resource_size,
  n_resources_ckan = nrow(resources_tbl),
  n_csv_resources = sum(resources_tbl$resource_format == "CSV", na.rm = TRUE),
  n_pdf_resources = sum(resources_tbl$resource_format == "PDF", na.rm = TRUE),
  n_spatial_resources = sum(resources_tbl$resource_format %in% c("FGDB", "GeoJSON", "GPKG", "REST", "WMS"), na.rm = TRUE),
  n_rows_stations = nrow(stations),
  n_cols_stations_source = ncol(stations_raw),
  n_cols_stations_prepared = ncol(stations),
  n_rows_aires_drainage = nrow(aires_drainage),
  n_cols_aires_source = ncol(aires_raw),
  n_cols_aires_prepared = ncol(aires_drainage),
  n_rows_joined = nrow(stations_aires),
  n_cols_joined = ncol(stations_aires),
  min_year = min(stations$annee, na.rm = TRUE),
  max_year = max(stations$annee, na.rm = TRUE),
  n_stations = n_distinct(stations$no_bqma),
  n_hydronymes = n_distinct(stations$hydronyme),
  n_type_station = n_distinct(stations$type_station),
  n_type_suivi = n_distinct(stations$type_suivi),
  n_rows_with_coordinates = sum(!is.na(stations$latitude) & !is.na(stations$longitude)),
  pct_rows_with_coordinates = round(mean(!is.na(stations$latitude) & !is.na(stations$longitude)) * 100, 2),
  n_stations_with_drainage = n_distinct(aires_drainage$no_bqma)
)

missing_tbl <- stations |>
  summarise(across(everything(), ~ sum(is.na(.x)))) |>
  pivot_longer(everything(), names_to = "variable", values_to = "n_missing") |>
  mutate(
    n_rows = nrow(stations),
    pct_missing = round(n_missing / n_rows * 100, 2)
  ) |>
  arrange(desc(n_missing), variable)

indicator_summary_tbl <- stations |>
  summarise(
    across(
      all_of(indicator_columns),
      list(
        n_missing = ~ sum(is.na(.x)),
        min = ~ min(.x, na.rm = TRUE),
        q1 = ~ quantile(.x, 0.25, na.rm = TRUE, names = FALSE),
        median = ~ median(.x, na.rm = TRUE),
        mean = ~ mean(.x, na.rm = TRUE),
        q3 = ~ quantile(.x, 0.75, na.rm = TRUE, names = FALSE),
        max = ~ max(.x, na.rm = TRUE)
      ),
      .names = "{.col}__{.fn}"
    )
  ) |>
  pivot_longer(everything(), names_to = "metric", values_to = "value") |>
  separate(metric, into = c("variable", "statistic"), sep = "__") |>
  pivot_wider(names_from = statistic, values_from = value) |>
  mutate(
    n_rows = nrow(stations),
    pct_missing = round(n_missing / n_rows * 100, 2)
  ) |>
  select(variable, n_rows, n_missing, pct_missing, min, q1, median, mean, q3, max)

types_station_tbl <- stations |>
  count(type_station, name = "n_observations", sort = TRUE) |>
  mutate(pct_observations = round(n_observations / sum(n_observations) * 100, 1))

types_suivi_tbl <- stations |>
  count(type_suivi, name = "n_observations", sort = TRUE) |>
  mutate(pct_observations = round(n_observations / sum(n_observations) * 100, 1))

bassins_tbl <- stations |>
  mutate(bv_n1m = if_else(is.na(bv_n1m), "Non renseigné", bv_n1m)) |>
  count(bv_n1m, name = "n_observations", sort = TRUE) |>
  mutate(pct_observations = round(n_observations / sum(n_observations) * 100, 1))

annees_tbl <- stations |>
  count(annee, name = "n_observations") |>
  arrange(annee) |>
  mutate(n_stations = vapply(annee, function(y) n_distinct(stations$no_bqma[stations$annee == y]), integer(1)))

stations_longues_tbl <- stations |>
  filter(!is.na(ptot_med_mgl)) |>
  group_by(no_bqma, hydronyme, bv_n1m) |>
  summarise(
    n_years = n_distinct(annee),
    min_year = min(annee, na.rm = TRUE),
    max_year = max(annee, na.rm = TRUE),
    median_ptot_mgl = median(ptot_med_mgl, na.rm = TRUE),
    median_iqbp = median(iqbp_med, na.rm = TRUE),
    .groups = "drop"
  ) |>
  arrange(desc(n_years), desc(median_ptot_mgl), no_bqma)

aires_summary_tbl <- aires_drainage |>
  summarise(
    n_stations = n_distinct(no_bqma),
    min_superf_tot_km2 = min(superf_tot_km2, na.rm = TRUE),
    median_superf_tot_km2 = median(superf_tot_km2, na.rm = TRUE),
    max_superf_tot_km2 = max(superf_tot_km2, na.rm = TRUE),
    median_pc_foret = median(pc_foret, na.rm = TRUE),
    median_pc_agricole = median(pc_agricole, na.rm = TRUE),
    max_pc_agricole = max(pc_agricole, na.rm = TRUE),
    median_pc_anthropique = median(pc_anthropique, na.rm = TRUE)
  )

write_processed_csv(resources_tbl, "ressources_ckan_suivi_rivieres.csv")
write_processed_csv(stations, "stations_qualite_eau.csv")
write_processed_csv(aires_drainage, "aires_drainage.csv")
write_processed_csv(stations_aires, "stations_qualite_eau_aires.csv")
write_processed_csv(summary_tbl, "resume_suivi_rivieres.csv")
write_processed_csv(missing_tbl, "valeurs_manquantes_suivi_rivieres.csv")
write_processed_csv(indicator_summary_tbl, "resume_indicateurs_suivi_rivieres.csv")
write_processed_csv(types_station_tbl, "resume_types_station_suivi_rivieres.csv")
write_processed_csv(types_suivi_tbl, "resume_types_suivi_suivi_rivieres.csv")
write_processed_csv(bassins_tbl, "resume_bassins_suivi_rivieres.csv")
write_processed_csv(annees_tbl, "resume_annees_suivi_rivieres.csv")
write_processed_csv(stations_longues_tbl, "stations_longues_phosphore_suivi_rivieres.csv")
write_processed_csv(aires_summary_tbl, "resume_aires_drainage_suivi_rivieres.csv")

stopifnot(nrow(resources_tbl) == 9)
stopifnot(summary_tbl$n_csv_resources == 1)
stopifnot(nrow(stations) == 6990)
stopifnot(nrow(aires_drainage) == 866)
stopifnot(nrow(stations_aires) == 6990)
stopifnot(summary_tbl$n_stations == 935)
stopifnot(summary_tbl$min_year == 2000)
stopifnot(summary_tbl$max_year == 2024)
stopifnot(all(c("ptot_med_mgl", "iqbp_med", "cf_med_ufc") %in% indicator_summary_tbl$variable))

message("Fichier brut : ", zip_path)
message("Fichiers préparés dans ", processed_dir, "/")

record_preparation("suivi-rivieres-fleuve")
