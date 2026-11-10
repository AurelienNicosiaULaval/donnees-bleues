# Préparer les liens école-immeuble nécessaires aux deux activités.
library(dplyr)
library(readr)

preparer_ecoles_api <- function(fichier) {
  donnees <- read_csv(fichier, show_col_types = FALSE)
  attendues <- c('CD_ORGNS', 'CD_IMM', 'COORD_X_LL84_IMM', 'COORD_Y_LL84_IMM',
                 'NOM_REG_ADM', 'TYPE_CS', 'PRESC', 'PRIM', 'SEC', 'FORM_PRO', 'ADULTE')
  if (length(setdiff(attendues, names(donnees)))) stop('Champs scolaires absents.', call. = FALSE)
  if (!nrow(donnees) || anyNA(donnees$COORD_X_LL84_IMM) || anyNA(donnees$COORD_Y_LL84_IMM) ||
      any(!unlist(donnees[c('PRESC','PRIM','SEC','FORM_PRO','ADULTE')]) %in% c(0, 1)))
    stop('Données scolaires incomplètes ou indicateurs inattendus.', call. = FALSE)
  resultat <- donnees |>
    transmute(CD_ORGNS, CD_IMM, lien_ecole_immeuble_id = paste(CD_ORGNS, CD_IMM, sep = '-'),
      longitude = COORD_X_LL84_IMM, latitude = COORD_Y_LL84_IMM,
      region_administrative = NOM_REG_ADM,
      type_reseau_public = case_when(TYPE_CS == 'Franco' ~ 'Francophone',
        TYPE_CS == 'Anglo' ~ 'Anglophone', TYPE_CS == 'Statut' ~ 'Statut particulier', TRUE ~ TYPE_CS))
  if (anyDuplicated(resultat$lien_ecole_immeuble_id) ||
      any(resultat$longitude < -80 | resultat$longitude > -55 | resultat$latitude < 44 | resultat$latitude > 63))
    stop('Identifiants répétés ou coordonnées hors de l’étendue attendue.', call. = FALSE)
  resultat
}
