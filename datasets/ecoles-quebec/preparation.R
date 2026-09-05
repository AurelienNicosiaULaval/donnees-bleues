source("R/utils_downloads.R")
# Préparation : Établissements scolaires du Québec
# Source officielle : https://www.donneesquebec.ca/recherche/dataset/localisation-des-etablissements-d-enseignement-du-reseau-scolaire-au-quebec

library(dplyr)
library(readr)

dataset_id <- "ecoles-quebec"

raw_dir <- file.path("data", "raw", dataset_id)
processed_dir <- file.path("data", "processed", dataset_id)

dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(processed_dir, recursive = TRUE, showWarnings = FALSE)

source_url <- "https://www.donneesquebec.ca/recherche/dataset/2d3b5cf8-b347-49c7-ad3b-bd6a9c15e443/resource/c6640a54-bc4b-43ec-864e-6c325dce61bc/download/pps_public_ecole.csv"
raw_path <- file.path(raw_dir, "pps_public_ecole.csv")
processed_path <- file.path(processed_dir, "ecoles_publiques_quebec.csv")

download_source(source_url, raw_path, mode = "wb", quiet = TRUE)

expected_columns <- c(
  "DT_MAJ_GDUNO",
  "COMBINE_NUO_NUI",
  "CD_ORGNS",
  "NOM_COURT_ORGNS",
  "NOM_OFFCL_ORGNS",
  "ADRS_GEO_L1_GDUNO_ORGNS",
  "ADRS_GEO_L2_GDUNO_ORGNS",
  "CD_POSTL_GDUNO_ORGNS",
  "CD_MUNCP_GDUNO_ORGNS",
  "NOM_MUNCP_GDUNO_ORGNS",
  "CD_IMM",
  "NOM_IMM",
  "ADRS_GEO_L1_GDUNO_IMM",
  "ADRS_GEO_L2_GDUNO_IMM",
  "CD_MUNCP_GDUNO_IMM",
  "NOM_MUNCP_GDUNO_IMM",
  "CD_POSTL_GDUNO_IMM",
  "PRESC",
  "PRIM",
  "SEC",
  "FORM_PRO",
  "ADULTE",
  "SITE_WEB_ORGNS",
  "COORD_X_LL84_IMM",
  "COORD_Y_LL84_IMM",
  "ORDRE_ENS",
  "CD_CS",
  "TYPE_CS",
  "STYLE_CART",
  "NOM_MUNCP",
  "NOM_MRC",
  "NOM_REG_ADM",
  "NOM_CEP",
  "NOM_CS"
)

ecoles_raw <- read_csv(raw_path, show_col_types = FALSE)

missing_columns <- setdiff(expected_columns, names(ecoles_raw))

if (length(missing_columns) > 0) {
  stop(
    "Colonnes attendues absentes : ",
    paste(missing_columns, collapse = ", "),
    call. = FALSE
  )
}

if (nrow(ecoles_raw) == 0) {
  stop("Le fichier source ne contient aucune ligne.", call. = FALSE)
}

indicator_columns <- c("PRESC", "PRIM", "SEC", "FORM_PRO", "ADULTE")

valid_indicators <- ecoles_raw |>
  summarise(across(all_of(indicator_columns), ~ all(.x %in% c(0, 1)))) |>
  unlist(use.names = FALSE)

if (!all(valid_indicators)) {
  stop("Les indicateurs d'ordre d'enseignement doivent être codés 0/1.", call. = FALSE)
}

if (any(is.na(ecoles_raw$COORD_X_LL84_IMM) | is.na(ecoles_raw$COORD_Y_LL84_IMM))) {
  stop("Certaines coordonnées d'immeubles sont manquantes.", call. = FALSE)
}

if (
  any(ecoles_raw$COORD_X_LL84_IMM < -80 | ecoles_raw$COORD_X_LL84_IMM > -55) ||
    any(ecoles_raw$COORD_Y_LL84_IMM < 44 | ecoles_raw$COORD_Y_LL84_IMM > 63)
) {
  stop("Certaines coordonnées sont hors de l'étendue attendue pour le Québec.", call. = FALSE)
}

ecoles <- ecoles_raw |>
  select(all_of(expected_columns)) |>
  mutate(
    lien_ecole_immeuble_id = paste(CD_ORGNS, CD_IMM, sep = "-"),
    longitude = COORD_X_LL84_IMM,
    latitude = COORD_Y_LL84_IMM,
    region_administrative = NOM_REG_ADM,
    mrc = NOM_MRC,
    municipalite = NOM_MUNCP,
    centre_services_nom = NOM_CS,
    type_reseau_public = case_when(
      TYPE_CS == "Franco" ~ "Francophone",
      TYPE_CS == "Anglo" ~ "Anglophone",
      TYPE_CS == "Statut" ~ "Statut particulier",
      TRUE ~ TYPE_CS
    ),
    est_prescolaire = PRESC == 1,
    est_primaire = PRIM == 1,
    est_secondaire = SEC == 1,
    est_formation_professionnelle = FORM_PRO == 1,
    est_adulte = ADULTE == 1,
    nb_ordres_autorises = PRESC + PRIM + SEC + FORM_PRO + ADULTE
  )

if (n_distinct(ecoles$lien_ecole_immeuble_id) != nrow(ecoles)) {
  stop("L'identifiant local école-immeuble n'est pas unique.", call. = FALSE)
}

write_csv(ecoles, processed_path)

message("Fichier préparé : ", processed_path)
message("Lignes : ", nrow(ecoles))
message("Colonnes : ", ncol(ecoles))
message("Organismes distincts : ", n_distinct(ecoles$CD_ORGNS))
message("Immeubles distincts : ", n_distinct(ecoles$CD_IMM))
message("Régions administratives : ", n_distinct(ecoles$region_administrative))

record_preparation("ecoles-quebec")
