# Source figée : Aurélien Nicosia, arbres_quebec, version 1.0.0.
# Données MRNF / PET5, extraction du 25 juin 2026, CC BY 4.0 ; VASCAN, CC0.
# Exécuter depuis la racine du dépôt Données bleues.
library(readr)
library(dplyr)
library(digest)
source("R/utils_downloads.R")

id <- "arbres-quebec"
version <- "v1.0.0"
base_url <- paste0("https://raw.githubusercontent.com/AurelienNicosiaULaval/arbres_quebec/", version, "/data_clean/")
raw_dir <- file.path("data/raw", id)
processed_dir <- file.path("data/processed", id)
dir.create(processed_dir, recursive = TRUE, showWarnings = FALSE)
files <- c("arbres_quebec_small.csv", "arbres_quebec_small_dictionary.csv",
           "arbres_quebec_small_provenance.csv", "small_sampling_manifest.csv")
for (file in files) {
  download_source(paste0(base_url, file), file.path(raw_dir, file))
}
input <- file.path(raw_dir, files[1])
expected_sha <- "1af11ff0fc824f35286987928f0423441540ece1badb674f347ab05db07d4ccf"
stopifnot(identical(digest(input, algo = "sha256", file = TRUE), expected_sha))
arbres <- read_csv(input, col_types = cols(.default = col_guess(),
  plot_id = col_character(), tree_id = col_character(), record_id = col_character()),
  show_col_types = FALSE)
stopifnot(nrow(arbres) == 200, ncol(arbres) == 21,
          n_distinct(arbres$plot_id) == 200, !anyDuplicated(arbres$record_id),
          all((arbres |> count(species))$n == 50),
          all(is.finite(arbres$diameter_cm)), all(arbres$diameter_cm > 0),
          all(is.finite(arbres$height_m)), all(arbres$height_m > 0),
          sum(is.na(arbres$age_years)) == 52,
          all(is.na(arbres$age_years[arbres$species_code == "ERR"])),
          identical(range(arbres$survey_year), c(2015, 2025)),
          max(abs(arbres$basal_area_m2 - pi * (arbres$diameter_cm / 200)^2)) < 1e-12)
# Copie octet pour octet : la préparation ne recalcule pas l’échantillon publié.
for (file in files) {
  stopifnot(file.copy(file.path(raw_dir, file), file.path(processed_dir, file), overwrite = TRUE))
}
record_preparation(id)
message("Version 1.0.0 vérifiée : 200 arbres, 21 colonnes, identifiants conservés.")
