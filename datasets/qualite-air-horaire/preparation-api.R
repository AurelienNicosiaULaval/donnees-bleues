# Résumer les mesures horaires publiées en jours de mesure, en HNE fixe.
library(dplyr)
library(readr)
library(tidyr)
library(stringr)
preparer_air_horaire_api <- function(fichier) {
  x <- readr::read_csv(fichier, col_types = readr::cols(Station = readr::col_character(),
    Date_Heure = readr::col_character(), .default = readr::col_double()), show_col_types = FALSE)
  readr::stop_for_problems(x)
  polluants <- c('BC_880nm', 'CO', 'H2S', 'NO2-CAPS', 'NO2', 'NO-CAPS', 'NO',
    'O3', 'PM0.1-CPC', 'PM2.5-T640', 'SO2')
  if (!all(c('Station', 'Date_Heure', polluants) %in% names(x)) || !nrow(x) ||
      anyNA(x$Station) || anyNA(x$Date_Heure) || anyDuplicated(x[c('Station', 'Date_Heure')]))
    stop('Structure ou clé des mesures horaires invalide.', call. = FALSE)
  unites <- c('BC_880nm' = 'µg/m³', 'CO' = 'ppm', 'H2S' = 'ppb',
    'NO2-CAPS' = 'ppb', 'NO2' = 'ppb', 'NO-CAPS' = 'ppb', 'NO' = 'ppb',
    'O3' = 'ppb', 'PM0.1-CPC' = 'k part/cm³', 'PM2.5-T640' = 'µg/m³', 'SO2' = 'ppb')
  etiquettes <- c('BC_880nm' = 'BC 880 nm', setNames(polluants[-1], polluants[-1]))
  heure <- as.POSIXct(x$Date_Heure, tz = 'Etc/GMT+5')
  if (anyNA(heure)) stop('Heure de mesure RSQAQ illisible.', call. = FALSE)
  mesures <- x |>
    mutate(station_id = str_extract(Station, '^\\d+'),
      station_name = str_squish(str_remove(Station, '^\\d+\\s*-\\s*')),
      date_heure = heure, date = as.Date(heure - 1, tz = 'Etc/GMT+5')) |>
    pivot_longer(cols = all_of(polluants), names_to = 'contaminant_source', values_to = 'concentration') |>
    filter(!is.na(concentration), format(date, '%Y') == '2025') |>
    mutate(contaminant = unname(etiquettes[contaminant_source]), unite = unname(unites[contaminant_source]))
  if (!nrow(mesures) || anyNA(mesures$station_id)) stop('Mesures ou identifiants de stations absents.', call. = FALSE)
  resume <- mesures |>
    group_by(contaminant_source) |>
    summarise(n_mesures = n(), n_stations = n_distinct(station_id),
      premiere_mesure = min(date_heure), derniere_mesure = max(date_heure),
      moyenne_horaire = mean(concentration), mediane_horaire = median(concentration),
      p95_horaire = as.numeric(quantile(concentration, .95)), maximum_horaire = max(concentration),
      .groups = 'drop')
  mesures |>
    group_by(date, station_id, station_name, contaminant_source, contaminant, unite) |>
    summarise(n_heures_valides = n(), moyenne = mean(concentration), mediane = median(concentration),
      p95 = as.numeric(quantile(concentration, .95)), maximum = max(concentration), .groups = 'drop') |>
    mutate(source_year = 2025L, .before = 1) |>
    left_join(resume, by = 'contaminant_source') |>
    arrange(date, station_id, contaminant_source)
}
