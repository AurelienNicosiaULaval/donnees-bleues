source("R/utils_downloads.R")
# Préparation : Indices de défavorisation des écoles primaires du Québec
# Source officielle : Données Québec / Ministère de l'Éducation

library(dplyr)
library(readr)

dataset_id <- "defavorisation-ecoles-primaires"

raw_dir <- file.path("data", "raw", dataset_id)
processed_dir <- file.path("data", "processed", dataset_id)

dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(processed_dir, recursive = TRUE, showWarnings = FALSE)

source_url <- "https://www.donneesquebec.ca/recherche/dataset/004de02c-19f1-4da0-9af8-33f893e41972/resource/6c5d4a5d-ba3b-40a6-b570-916f43ab622c/download/defav_ecole_prim_public.csv"
raw_path <- file.path(raw_dir, "defav_ecole_prim_public.csv")
processed_path <- file.path(processed_dir, "defavorisation_ecoles_primaires.csv")

download_source(source_url, raw_path, mode = "wb", quiet = TRUE)

expected_columns <- c(
  "Code_Cs",
  "Nom_Cs",
  "Code_Org",
  "Nom_Org",
  "IMSE",
  "Rang_Decile_IMSE",
  "SFR",
  "Rang_Decile_SFR",
  "Nbre_Eleves",
  "Diffusion",
  "Annee_Scol"
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

if (!all(ecoles_raw$Diffusion %in% c("OUI", "NON"))) {
  stop("La variable Diffusion contient des valeurs inattendues.", call. = FALSE)
}

if (!all(unique(ecoles_raw$Annee_Scol) == "2025-2026")) {
  stop("L'année scolaire attendue est 2025-2026.", call. = FALSE)
}

if (any(ecoles_raw$Diffusion == "NON" & !is.na(ecoles_raw$IMSE))) {
  stop("Des lignes non diffusées contiennent un IMSE.", call. = FALSE)
}

ecoles <- ecoles_raw |>
  select(all_of(expected_columns)) |>
  mutate(
    diffusion_indices = Diffusion == "OUI",
    groupe_imse = case_when(
      Rang_Decile_IMSE %in% 8:10 ~ "Déciles 8 à 10",
      Rang_Decile_IMSE %in% 1:7 ~ "Déciles 1 à 7",
      TRUE ~ "Non diffusé"
    )
  )

write_csv(ecoles, processed_path)

message("Fichier préparé : ", processed_path)
message("Lignes : ", nrow(ecoles))
message("Colonnes : ", ncol(ecoles))
message("Lignes diffusées : ", sum(ecoles$diffusion_indices))
message("Lignes non diffusées : ", sum(!ecoles$diffusion_indices))

record_preparation("defavorisation-ecoles-primaires")
