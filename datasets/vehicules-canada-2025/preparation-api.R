# Refaire les comptes région-carburant sans diffuser les données individuelles.
library(readr)
library(dplyr)
library(digest)
preparer_parc_api <- function(fichier) {
  if (!identical(digest::digest(file = fichier, algo = 'sha256'), '84f57d77dca8eee189c734c79cde757bf0311ebb5d26694278c31b4db7e331f9'))
    stop('La source SAAQ 2022 diffère de la version de référence.', call. = FALSE)
  colonnes <- c('AN', 'CLAS', 'TYP_VEH_CATEG_USA', 'TYP_CARBU', 'REG_ADM')
  entete <- names(readr::read_csv(fichier, n_max = 0, show_col_types = FALSE))
  if (!all(colonnes %in% entete)) stop('Champs SAAQ manquants.', call. = FALSE)
  morceaux <- list()
  callback <- readr::SideEffectChunkCallback$new(function(morceau, position) {
    resume <- morceau |>
      filter(AN == '2022', TYP_VEH_CATEG_USA == 'AU', CLAS %in% c('PAU', 'CAU', 'RAU')) |>
      count(AN, REG_ADM, TYP_CARBU, name = 'number_registered_qc')
    morceaux[[length(morceaux) + 1L]] <<- resume
  })
  readr::read_csv_chunked(fichier, callback = callback, chunk_size = 200000,
    col_types = readr::cols_only(AN = readr::col_character(), CLAS = readr::col_character(),
      TYP_VEH_CATEG_USA = readr::col_character(), TYP_CARBU = readr::col_character(), REG_ADM = readr::col_character()),
    na = c('', 'NA'), progress = FALSE, show_col_types = FALSE)
  if (!length(morceaux)) stop('Aucune donnée SAAQ.', call. = FALSE)
  x <- bind_rows(morceaux) |>
    group_by(AN, REG_ADM, TYP_CARBU) |>
    summarise(number_registered_qc = sum(number_registered_qc), .groups = 'drop')
  codes <- readr::read_csv('datasets/vehicules-canada-2025/saaq-fuel-codes.csv',
    col_types = readr::cols(.default = readr::col_character()), na = character(), show_col_types = FALSE) |>
    transmute(saaq_fuel_code = na_if(trimws(code), ''), saaq_fuel_type = label_fr)
  resultat <- x |>
    transmute(saaq_snapshot_year = as.integer(AN), region_qc = trimws(REG_ADM),
      saaq_fuel_code = na_if(trimws(TYP_CARBU), ''), number_registered_qc) |>
    left_join(codes, by = 'saaq_fuel_code', na_matches = 'na') |>
    mutate(saaq_fuel_type = case_when(!is.na(saaq_fuel_type) ~ saaq_fuel_type,
      is.na(saaq_fuel_code) ~ 'Non précisé', TRUE ~ paste0('Code inconnu: ', saaq_fuel_code))) |>
    select(saaq_snapshot_year, region_qc, saaq_fuel_code, saaq_fuel_type, number_registered_qc) |>
    arrange(region_qc, saaq_fuel_code)
  if (nrow(resultat) != 152L || sum(resultat$number_registered_qc) != 5507330L)
    stop('Le périmètre du parc SAAQ ne correspond pas à la référence.', call. = FALSE)
  resultat
}
