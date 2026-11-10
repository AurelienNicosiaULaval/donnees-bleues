# Conserver les suppressions de diffusion de la source et l'année scolaire de l'activité.
library(dplyr)
library(readr)
preparer_defavorisation_api <- function(fichier) {
  x <- readr::read_csv(fichier, show_col_types = FALSE)
  champs <- c('Code_Org', 'Nom_Org', 'IMSE', 'Rang_Decile_IMSE', 'SFR',
              'Rang_Decile_SFR', 'Nbre_Eleves', 'Diffusion', 'Annee_Scol')
  if (!all(champs %in% names(x)) || !nrow(x) || anyNA(x$Diffusion) ||
      any(!x$Diffusion %in% c('OUI', 'NON')) || anyNA(x$Annee_Scol) || any(x$Annee_Scol != '2025-2026'))
    stop('Structure ou année scolaire inattendue.', call. = FALSE)
  sensibles <- c('IMSE', 'Rang_Decile_IMSE', 'SFR', 'Rang_Decile_SFR', 'Nbre_Eleves')
  if (any(!is.na(as.matrix(x[x$Diffusion == 'NON', sensibles]))))
    stop('Une valeur est présente pour une école non diffusée.', call. = FALSE)
  x |>
    select(all_of(champs)) |>
    mutate(groupe_imse = case_when(Rang_Decile_IMSE %in% 8:10 ~ 'Déciles 8 à 10',
      Rang_Decile_IMSE %in% 1:7 ~ 'Déciles 1 à 7', TRUE ~ 'Non diffusé'))
}
