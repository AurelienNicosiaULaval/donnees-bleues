source("R/utils_downloads.R")
# Préparation : Météo quotidienne à Québec
# Source pédagogique : UlavalSSD::MeteoQuebec 0.2.0
# Source primaire documentée : Environnement et Changement climatique Canada via weathercan

library(dplyr)
library(lubridate)
library(readr)
library(tidyr)
library(UlavalSSD)

processed_dir <- "data/processed/meteo-quebec"
dir.create(processed_dir, recursive = TRUE, showWarnings = FALSE)

source_dataset <- "UlavalSSD::MeteoQuebec"
source_primary <- "Environnement et Changement climatique Canada via weathercan"
access_date <- as.character(Sys.Date())

meteo_quebec <- MeteoQuebec |>
  transmute(
    source_dataset = source_dataset,
    station_label = "Québec/Jean-Lesage",
    date = make_date(year, as.integer(month), as.integer(day)),
    annee = year,
    mois_num = as.integer(month),
    mois = month(date, label = TRUE, abbr = FALSE),
    jour = as.integer(day),
    saison = case_when(
      mois_num %in% c(12L, 1L, 2L) ~ "Hiver",
      mois_num %in% c(3L, 4L, 5L) ~ "Printemps",
      mois_num %in% c(6L, 7L, 8L) ~ "Été",
      mois_num %in% c(9L, 10L, 11L) ~ "Automne",
      TRUE ~ NA_character_
    ),
    max_temp,
    mean_temp,
    min_temp,
    total_precip,
    total_rain,
    total_snow,
    snow_grnd
  ) |>
  arrange(date)

missing_summary <- meteo_quebec |>
  summarise(across(everything(), ~ sum(is.na(.x)))) |>
  pivot_longer(
    cols = everything(),
    names_to = "variable",
    values_to = "n_missing"
  ) |>
  mutate(
    n_rows = nrow(meteo_quebec),
    pct_missing = round(100 * n_missing / n_rows, 2)
  ) |>
  arrange(desc(n_missing), variable)

season_summary <- meteo_quebec |>
  group_by(saison) |>
  summarise(
    n = n(),
    mean_temp_moyenne = mean(mean_temp, na.rm = TRUE),
    ecart_type_temperature = sd(mean_temp, na.rm = TRUE),
    precipitation_moyenne = mean(total_precip, na.rm = TRUE),
    .groups = "drop"
  ) |>
  arrange(saison)

dataset_summary <- tibble::tibble(
  metric = c(
    "source_dataset",
    "source_primary",
    "access_date",
    "package_version_ulavalssd",
    "n_rows",
    "n_columns_prepared",
    "date_min",
    "date_max",
    "mean_temperature_mean",
    "mean_temperature_min",
    "mean_temperature_max",
    "total_precipitation_mean",
    "total_precipitation_max"
  ),
  value = c(
    source_dataset,
    source_primary,
    access_date,
    as.character(packageVersion("UlavalSSD")),
    as.character(nrow(meteo_quebec)),
    as.character(ncol(meteo_quebec)),
    as.character(min(meteo_quebec$date, na.rm = TRUE)),
    as.character(max(meteo_quebec$date, na.rm = TRUE)),
    as.character(round(mean(meteo_quebec$mean_temp, na.rm = TRUE), 2)),
    as.character(min(meteo_quebec$mean_temp, na.rm = TRUE)),
    as.character(max(meteo_quebec$mean_temp, na.rm = TRUE)),
    as.character(round(mean(meteo_quebec$total_precip, na.rm = TRUE), 2)),
    as.character(max(meteo_quebec$total_precip, na.rm = TRUE))
  )
)

stopifnot(
  as.character(packageVersion("UlavalSSD")) == "0.2.0",
  nrow(meteo_quebec) == 20111,
  ncol(meteo_quebec) == 15,
  min(meteo_quebec$date, na.rm = TRUE) == as.Date("1970-01-01"),
  max(meteo_quebec$date, na.rm = TRUE) == as.Date("2025-01-22"),
  sum(is.na(meteo_quebec$mean_temp)) == 54,
  sum(is.na(meteo_quebec$total_precip)) == 97,
  sum(is.na(meteo_quebec$total_rain)) == 10490,
  sum(is.na(meteo_quebec$total_snow)) == 10587,
  sum(is.na(meteo_quebec$snow_grnd)) == 8912
)

write_csv(
  meteo_quebec,
  file.path(processed_dir, "meteo_quebec.csv")
)

write_csv(
  missing_summary,
  file.path(processed_dir, "valeurs_manquantes_meteo_quebec.csv")
)

write_csv(
  season_summary,
  file.path(processed_dir, "resume_saisons_meteo_quebec.csv")
)

write_csv(
  dataset_summary,
  file.path(processed_dir, "resume_meteo_quebec.csv")
)

message("Source pédagogique : ", source_dataset)
message("Source primaire : ", source_primary)
message("Fichier préparé : ", file.path(processed_dir, "meteo_quebec.csv"))
message("Observations quotidiennes : ", nrow(meteo_quebec))

raw_package_path <- "data/raw/meteo-quebec/UlavalSSD_MeteoQuebec.csv"
dir.create(dirname(raw_package_path), recursive = TRUE, showWarnings = FALSE)
write_csv(MeteoQuebec, raw_package_path)
record_source(raw_package_path, "https://github.com/AurelienNicosiaULaval/UlavalSSD/tree/0b79f4c985ef87a32bdb5b83f193ae5f5ea6d640",
              kind = "package_export", details = list(package = "UlavalSSD", version = as.character(packageVersion("UlavalSSD")), dataset = "MeteoQuebec"))

record_preparation("meteo-quebec")
