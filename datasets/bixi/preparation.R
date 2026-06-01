# Préparer un instantané des stations BIXI depuis les flux GBFS.

library(dplyr)
library(jsonlite)
library(readr)
library(tidyr)

dir.create("data/raw/bixi", recursive = TRUE, showWarnings = FALSE)
dir.create("data/processed/bixi", recursive = TRUE, showWarnings = FALSE)

station_information_url <- "https://gbfs.velobixi.com/gbfs/fr/station_information.json"
station_status_url <- "https://gbfs.velobixi.com/gbfs/fr/station_status.json"

download.file(station_information_url, "data/raw/bixi/station_information.json", mode = "wb", quiet = TRUE)
download.file(station_status_url, "data/raw/bixi/station_status.json", mode = "wb", quiet = TRUE)

station_information <- fromJSON("data/raw/bixi/station_information.json", flatten = TRUE)$data$stations
station_status <- fromJSON("data/raw/bixi/station_status.json", flatten = TRUE)$data$stations

stations <- station_information |>
  left_join(station_status, by = "station_id", suffix = c("_information", "_status")) |>
  mutate(
    last_reported_datetime = as.POSIXct(last_reported, origin = "1970-01-01", tz = "America/Toronto"),
    capacity = as.integer(capacity),
    num_bikes_available = as.integer(num_bikes_available),
    num_ebikes_available = as.integer(num_ebikes_available),
    num_docks_available = as.integer(num_docks_available)
  ) |>
  select(
    station_id,
    name,
    short_name,
    lat,
    lon,
    capacity,
    num_bikes_available,
    num_ebikes_available,
    num_docks_available,
    is_installed,
    is_renting,
    is_returning,
    last_reported_datetime
  )

write_csv(stations, "data/processed/bixi/stations_bixi_snapshot.csv")

message("Fichier préparé : data/processed/bixi/stations_bixi_snapshot.csv")

