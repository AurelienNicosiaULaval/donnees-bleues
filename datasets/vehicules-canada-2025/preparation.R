# RNCan et SAAQ, jeu pédagogique dérivé par Aurélien Nicosia, version 1.0.0.
# Exécuter depuis la racine du projet Données bleues.
library(readr)
library(dplyr)
library(digest)
source("R/utils_downloads.R")

id <- "vehicules-canada-2025"
base_url <- "https://raw.githubusercontent.com/AurelienNicosiaULaval/vehicules-quebec/v1.0.0/data_clean/"
raw_dir <- file.path("data/raw", id)
processed_dir <- file.path("data/processed", id)
dir.create(processed_dir, recursive = TRUE, showWarnings = FALSE)
empreintes <- c(
  vehicules_canada_2025.csv = "170b7d662fe7ccf98ccf54c2a0e127648da36d0cb2d8554c5b7d39cefe238260",
  vehicules_canada_2025_dictionary.csv = "cff3ea74e974c740d5001ea12baf8a67d53ff80da92c6b6b83d8c72a76f0672d",
  vehicules_canada_2025_provenance.csv = "cff55da4af08c5150ec61958b96d2e1835c614dff8378b54e7b09ccad3cbbdba",
  parc_quebec_2022.csv = "4fb91d7190b9c6c62d97c2d23168a1c318206a969bfe3d255bc0d1c42cf30dca",
  parc_quebec_2022_dictionary.csv = "ee0044296e8b3c37c7a7cfd405e4a19b5d9a832482a3fb842fd11f359ff68a43")
for (file in names(empreintes)) {
  input <- file.path(raw_dir, file)
  download_source(paste0(base_url, file), input)
  stopifnot(identical(digest(input, algo = "sha256", file = TRUE), unname(empreintes[[file]])))
}
vehicules <- read_csv(file.path(raw_dir, "vehicules_canada_2025.csv"),
  col_types = cols(.default = col_guess(), vehicle_id = col_character()))
parc <- read_csv(file.path(raw_dir, "parc_quebec_2022.csv"),
  col_types = cols(.default = col_guess(), region_qc = col_character(), saaq_fuel_code = col_character()))
stopifnot(identical(dim(vehicules), c(64L, 19L)), !anyNA(vehicules),
  !anyDuplicated(vehicules$vehicle_id), !anyDuplicated(vehicules[c("make", "model")]),
  all(vehicules$model_year == 2025), n_distinct(vehicules$vehicle_class_group) == 5L,
  identical(dim(parc), c(152L, 5L)), all(parc$saaq_snapshot_year == 2022),
  !anyDuplicated(parc[c("region_qc", "saaq_fuel_code")]),
  sum(parc$number_registered_qc) == 5507330,
  !"number_registered_qc" %in% names(vehicules))
# Conserver les fichiers publiés octet pour octet, sans sélection ou jointure.
for (file in names(empreintes)) {
  stopifnot(file.copy(file.path(raw_dir, file), file.path(processed_dir, file), overwrite = TRUE))
}
record_preparation(id)
message("Version 1.0.0 vérifiée : 64 configurations et un tableau SAAQ distinct de 152 groupes.")
