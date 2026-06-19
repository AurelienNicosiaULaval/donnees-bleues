# Préparation : Réseaux de transport collectif GTFS au Québec
# Source officielle : https://www.donneesquebec.ca/recherche/dataset/rtc-gtfs-arrets-et-les-parcours
# Ce script est un gabarit. Il ne télécharge pas de fichier tant que la
# ressource officielle à utiliser en laboratoire n'a pas été choisie.

library(dplyr)
library(readr)
library(stringr)

source_page <- "https://www.donneesquebec.ca/recherche/dataset/rtc-gtfs-arrets-et-les-parcours"
raw_path <- "data_raw/source_officielle_a_renommer.csv"
processed_path <- "data_processed/transport_collectif.csv"

if (!file.exists(raw_path)) {
  stop(
    "Déposer d'abord la ressource officielle dans ", raw_path,
    ". Source : ", source_page,
    call. = FALSE
  )
}

donnees <- read_csv(raw_path, show_col_types = FALSE) |>
  rename_with(~ str_replace_all(str_to_lower(.x), "[^a-z0-9]+", "_")) |>
  rename_with(~ str_replace_all(.x, "(^_|_$)", ""))

write_csv(donnees, processed_path)
