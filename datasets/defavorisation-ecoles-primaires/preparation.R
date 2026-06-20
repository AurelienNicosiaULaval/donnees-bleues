# Préparation : Indices de défavorisation des écoles primaires du Québec
# Source officielle : Données Québec

library(dplyr)
library(readr)

dir.create("data_raw", showWarnings = FALSE)
dir.create("data_processed", showWarnings = FALSE)

source_url <- "https://www.donneesquebec.ca/recherche/dataset/004de02c-19f1-4da0-9af8-33f893e41972/resource/6c5d4a5d-ba3b-40a6-b570-916f43ab622c/download/defav_ecole_prim_public.csv"
raw_path <- "data_raw/defav_ecole_prim_public.csv"
processed_path <- "data_processed/defavorisation_ecoles_primaires.csv"

download.file(source_url, raw_path, mode = "wb", quiet = TRUE)

ecoles <- read_csv(raw_path, show_col_types = FALSE) |>
  mutate(
    diffusion_indices = Diffusion == "OUI"
  )

write_csv(ecoles, processed_path)

