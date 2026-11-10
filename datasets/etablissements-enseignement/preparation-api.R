# Harmoniser les neuf ressources en préservant l'unité de chacune.
library(dplyr)
library(readr)
preparer_etablissements_api <- function(fichiers) {
  if (!identical(names(fichiers), vapply(ressources_api, function(r) r$cle, character(1))))
    stop('Ensemble de ressources incomplet ou désordonné.', call. = FALSE)
  extraire <- function(x, candidats) {
    noms <- intersect(candidats, names(x))
    if (length(noms)) x[[noms[[1]]]] else rep(NA_character_, nrow(x))
  }
  tables <- lapply(ressources_api, function(r) {
    x <- readr::read_csv(fichiers[[r$cle]], col_types = readr::cols(.default = readr::col_character()), show_col_types = FALSE)
    cles <- switch(r$cle, public_ecole = c('CD_ORGNS', 'CD_IMM'), public_immeuble = 'CD_IMM', 'CD_ORGNS')
    if (!nrow(x) || !all(cles %in% names(x)) || anyNA(x[cles]) || anyDuplicated(x[cles]))
      stop('Clé absente ou répétée : ', r$cle, call. = FALSE)
    nom_organisme <- extraire(x, c('NOM_OFFCL_ORGNS', 'NOM_OFFCL'))
    nom_immeuble <- extraire(x, c('NOM_IMM', 'NOM_OFFCL_IMM'))
    tibble::tibble(source_resource = r$cle, resource_label = r$libelle,
      network_category = r$reseau, unit_kind = r$unite,
      code_organisme = extraire(x, c('CD_ORGNS', 'CD_ORGNS_RESP')),
      code_immeuble = extraire(x, 'CD_IMM'), nom = coalesce(nom_organisme, nom_immeuble),
      longitude = as.numeric(extraire(x, c('COORD_X_LL84_IMM','COORD_X_LL84'))),
      latitude = as.numeric(extraire(x, c('COORD_Y_LL84_IMM','COORD_Y_LL84'))),
      region_administrative = extraire(x, 'NOM_REG_ADM')) |>
      mutate(has_region = !is.na(region_administrative) & nzchar(region_administrative),
        has_coordinates = !is.na(longitude) & !is.na(latitude))
  })
  resultat <- bind_rows(tables)
  if (anyNA(resultat$nom) || any(is.na(resultat$longitude) != is.na(resultat$latitude)) ||
      any(resultat$longitude < -80 | resultat$longitude > -57, na.rm = TRUE) ||
      any(resultat$latitude < 44 | resultat$latitude > 63, na.rm = TRUE))
    stop('Nom ou coordonnées des établissements invalides.', call. = FALSE)
  resultat
}
