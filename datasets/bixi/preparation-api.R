# Préparer un instantané à partir des flux GBFS de BIXI.
library(dplyr)
library(jsonlite)
preparer_bixi_api <- function(information, statut) {
  info <- jsonlite::fromJSON(information)$data$stations
  etat <- jsonlite::fromJSON(statut)$data$stations
  info_requis <- c('station_id', 'name', 'capacity')
  etat_requis <- c('station_id', 'num_bikes_available', 'num_docks_available',
    'is_installed', 'is_renting', 'is_returning', 'last_reported')
  if (!nrow(info) || !nrow(etat) || !all(info_requis %in% names(info)) ||
      !all(etat_requis %in% names(etat)) || anyDuplicated(info$station_id) || anyDuplicated(etat$station_id))
    stop('Structure ou identifiants des stations GBFS invalides.', call. = FALSE)
  recu <- jsonlite::read_json(paste0(statut, '.source.json'))
  acquisition <- as.POSIXct(recu$acquired_at_utc, format = '%Y-%m-%dT%H:%M:%SZ', tz = 'UTC')
  if (is.na(acquisition)) stop('Date de collecte GBFS invalide.', call. = FALSE)
  info |>
    select(all_of(info_requis)) |>
    left_join(etat |> select(all_of(etat_requis)), by = 'station_id') |>
    mutate(capacity = as.numeric(capacity), num_bikes_available = as.numeric(num_bikes_available),
      num_docks_available = as.numeric(num_docks_available),
      groupe_capacite = case_when(is.na(capacity) ~ 'Capacité manquante',
        capacity <= 15 ~ 'Petite station, 15 bornes ou moins',
        capacity <= 25 ~ 'Station moyenne, 16 à 25 bornes',
        capacity <= 35 ~ 'Grande station, 26 à 35 bornes',
        TRUE ~ 'Très grande station, 36 bornes ou plus'),
      taux_occupation = if_else(!is.na(capacity) & capacity > 0, num_bikes_available / capacity, NA_real_),
      etat_operationnel = case_when(is_installed == 1 & is_renting == 1 & is_returning == 1 ~ 'Disponible pour location et retour',
        is_installed != 1 ~ 'Non installée', is_renting != 1 & is_returning != 1 ~ 'Location et retour indisponibles',
        is_renting != 1 ~ 'Location indisponible', is_returning != 1 ~ 'Retour indisponible', TRUE ~ 'État à vérifier'),
      last_reported_datetime = as.POSIXct(as.numeric(last_reported), origin = '1970-01-01', tz = 'UTC'),
      # Les horodatages antérieurs au lancement ou postérieurs à la collecte ne sont pas interprétables.
      # Source : https://www.donneesquebec.ca/recherche/organization/about/bixi
      last_reported_datetime = if_else(last_reported_datetime < as.POSIXct('2009-05-01', tz = 'UTC') |
        last_reported_datetime > acquisition, as.POSIXct(NA_character_, tz = 'UTC'), last_reported_datetime),
      snapshot_downloaded_at = acquisition) |>
    select(station_id, name, capacity, groupe_capacite, num_bikes_available, num_docks_available,
      taux_occupation, etat_operationnel, last_reported_datetime, snapshot_downloaded_at) |>
    arrange(name, station_id)
}
