# Transcription pédagogique du rapport de 1914, version figée 1.0.0.
# Exécuter depuis la racine du projet Données bleues.
library(readr)
library(digest)
source("R/utils_downloads.R")
id <- "empress-of-ireland"
base_url <- "https://raw.githubusercontent.com/AurelienNicosiaULaval/empress-of-ireland-data/v1.0.0/data_clean/"
raw_dir <- file.path("data/raw", id)
processed_dir <- file.path("data/processed", id)
dir.create(processed_dir, recursive = TRUE, showWarnings = FALSE)
empreintes <- c(
  empress_passengers.csv = "96ce103bc24af8366155330dca64525c35dadf38c70734b591d2ea75dfcb6437",
  empress_passenger_groups.csv = "3fb7b186d6f1b4b23e94f7bab4e1c45660acfc2860d14a4bbf537a28f07d0614",
  empress_crew_groups.csv = "dbfb3cd6c435a9e064dbdb252d3fe636bab291de9a3f577ca1982f5b1f482f1d",
  empress_sources_comparison.csv = "5d4b0726d6435909d7fccb676a0b187871f377e0b7307a58dd5bd3e679769f19")
for (file in names(empreintes)) {
  input <- file.path(raw_dir, file)
  download_source(paste0(base_url, file), input)
  stopifnot(identical(digest(input, algo = "sha256", file = TRUE), unname(empreintes[[file]])))
  stopifnot(file.copy(input, file.path(processed_dir, file), overwrite = TRUE))
}
passagers <- read_csv(file.path(processed_dir, "empress_passengers.csv"), show_col_types = FALSE)
equipage <- read_csv(file.path(processed_dir, "empress_crew_groups.csv"), show_col_types = FALSE)
stopifnot(identical(dim(passagers), c(24L, 7L)), !anyNA(passagers),
  !anyDuplicated(passagers[c("class", "sex", "age_group", "survived")]),
  all(passagers$frequency >= 0), all(passagers$frequency == floor(passagers$frequency)),
  sum(passagers$frequency) == 1057L,
  sum(passagers$frequency[passagers$survived == 1L]) == 217L,
  sum(equipage$total) == 420L, sum(equipage$survivors) == 248L)
record_preparation(id)
message("Version 1.0.0 vérifiée : 24 cellules, 1 057 passagers et un équipage distinct de 420 personnes.")
