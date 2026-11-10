# Préparer l'index des unités de téléchargement de la GRHQ.
library(dplyr)
library(readr)
library(stringr)
preparer_grhq_api <- function(fichier) {
  x <- readr::read_csv(fichier, col_types = readr::cols(.default = readr::col_character()), show_col_types = FALSE)
  if (!all(c('Bloc','Zone','FGDB') %in% names(x)) || !nrow(x) || anyNA(x$Bloc) ||
      anyNA(x$FGDB) || anyDuplicated(x$Bloc)) stop('Index hydrographique invalide.', call. = FALSE)
  recu <- jsonlite::read_json(paste0(fichier, '.source.json'))
  date_acces <- substr(recu$acquired_at_utc, 1, 10)
  x |>
    transmute(bloc = Bloc, region_hydrographique = stringr::str_extract(bloc, '^[0-9]+'),
      partie = as.integer(stringr::str_extract(bloc, '(?<=_)[0-9]+')),
      is_split_unit = !is.na(partie),
      unit_kind = if_else(is_split_unit, 'Partie de région hydrographique', 'Région hydrographique complète'),
      zone = Zone, fgdb_zip_file = basename(FGDB), fgdb_directory = dirname(FGDB), fgdb_url = FGDB,
      source_index_url = 'https://diffusion.mern.gouv.qc.ca/Diffusion/RGQ/Documentation/GRHQ/Index_GRHQ.csv',
      access_date = date_acces)
}
