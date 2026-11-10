# Préparer les marqueurs et les colonnes utiles aux deux activités.
library(dplyr)
library(readr)

preparer_niveaux_api <- function(fichier) {
  x <- readr::read_csv(fichier, show_col_types = FALSE)
  attendues <- c('id_msp', 'date_obs', 'type_obs', 'long_wgs84', 'lat_wgs84',
                 'alt_m_cgvd', 'err_xy_cm', 'err_z_cm')
  if (!all(attendues %in% names(x)) || !nrow(x)) stop('Champs des marqueurs absents.', call. = FALSE)
  resultat <- x |>
    transmute(id_msp, date_obs = as.Date(date_obs, format = '%Y/%m/%d'),
      annee_obs = as.integer(format(date_obs, '%Y')), type_obs,
      type_observation = case_when(type_obs == 'MAX' ~ 'Niveau maximal atteint',
        type_obs == 'ACT' ~ 'Niveau observé lors de la visite', TRUE ~ 'Autre ou non documenté'),
      long_wgs84, lat_wgs84, alt_m_cgvd, err_xy_cm, err_z_cm,
      has_coordinates = !is.na(long_wgs84) & !is.na(lat_wgs84)) |>
    arrange(date_obs, id_msp)
  if (anyNA(resultat$id_msp) || anyDuplicated(resultat$id_msp) ||
      anyNA(resultat$date_obs) || anyNA(resultat$type_obs))
    stop('Identifiants, dates ou types de marqueurs invalides.', call. = FALSE)
  resultat
}
