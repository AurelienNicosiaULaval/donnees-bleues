# Préparer les variables publiques nécessaires aux activités sur les prélèvements.
library(dplyr)
library(readr)
preparer_prelevements_api <- function(fichier) {
  x <- readr::read_csv(fichier, col_types = readr::cols(.default = readr::col_character()), show_col_types = FALSE)
  champs <- c('no_doc', 'Id', 'count_doc', 'vol_aut', 'vol_prec', 'eau_prov', 'long', 'lat')
  if (!all(champs %in% names(x)) || !nrow(x)) stop('Champs des prélèvements absents.', call. = FALSE)
  resultat <- x |>
    transmute(no_doc, site_id = Id, nombre_sites_document = as.integer(count_doc),
      volume_autorise_l_j = readr::parse_number(vol_aut), volume_autorise_m3_j = volume_autorise_l_j / 1000,
      precision_volume = vol_prec, provenance_eau = eau_prov,
      longitude = as.numeric(long), latitude = as.numeric(lat)) |>
    arrange(desc(volume_autorise_l_j), no_doc, site_id)
  # Un site peut figurer plusieurs fois dans le registre; conserver toutes les lignes.
  if (anyNA(resultat$site_id) || anyNA(resultat$no_doc))
    stop('Identifiants des prélèvements invalides.', call. = FALSE)
  resultat
}
