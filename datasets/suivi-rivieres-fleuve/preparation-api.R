# Mesures API et caractéristiques des aires de drainage de la copie du 5 septembre 2026.
library(dplyr)
library(readr)
library(digest)
preparer_rivieres_api <- function(fichier) {
  reference <- 'data/processed/suivi-rivieres-fleuve/stations_qualite_eau_aires.csv'
  empreinte <- '1be189251278697aea1f47297fe50f34318a6c334d2734a8f548a1bc52c3943b'
  if (!file.exists(reference) || !identical(digest::digest(file = reference, algo = 'sha256'), empreinte))
    stop('La table de référence des aires de drainage est absente ou modifiée.', call. = FALSE)
  aires <- readr::read_csv(reference, col_types = readr::cols(no_bqma = readr::col_character()),
    show_col_types = FALSE) |>
    distinct(no_bqma, pc_agricole)
  if (anyNA(aires$no_bqma) || anyDuplicated(aires$no_bqma))
    stop('Caractéristiques des aires ambiguës pour une station.', call. = FALSE)
  x <- readr::read_csv(fichier, col_types = readr::cols(NO_BQMA = readr::col_character()), show_col_types = FALSE)
  champs <- c('NO_BQMA','HYDRONYME','ANNEE','PTOT_MED_MGL','LATITUDE','LONGITUDE','BV_N1M')
  if (!all(champs %in% names(x)) || !nrow(x)) stop('Champs des stations absents.', call. = FALSE)
  resultat <- x |>
    transmute(no_bqma = NO_BQMA, hydronyme = HYDRONYME, annee = as.integer(ANNEE),
      ptot_med_mgl = as.numeric(PTOT_MED_MGL), latitude = as.numeric(LATITUDE),
      longitude = as.numeric(LONGITUDE), bv_n1m = BV_N1M) |>
    left_join(aires, by = 'no_bqma')
  if (anyNA(resultat$no_bqma) || anyNA(resultat$annee)) stop('Station ou année absente.', call. = FALSE)
  resultat
}
