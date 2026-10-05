# Préparer la compilation figée du 5 octobre 2026, sans téléchargement.
# Les archives HTML originales ont servi à la transcription, mais ne sont pas
# redistribuées. Ce script contrôle les tables publiques déjà relues.
library(readr)
library(dplyr)
library(purrr)
library(jsonlite)
library(digest)

id <- "camps-de-jour-quebec"
version <- "20261005T182735Z"
entree <- file.path("datasets", id, "downloads", version)
sortie <- file.path("data/processed", id)
manifest <- read_json(file.path(entree, "manifest_publication.json"), simplifyVector = FALSE)
dir.create(sortie, recursive = TRUE, showWarnings = FALSE)
for (table in manifest$tables) {
  chemin <- file.path(entree, table$file)
  stopifnot(digest(file = chemin, algo = "sha256") == table$sha256)
  donnees <- read_csv(chemin, col_types = cols(.default = col_character()), show_col_types = FALSE)
  stopifnot(nrow(donnees) == table$rows, identical(names(donnees), unlist(table$columns)))
  stopifnot(file.copy(chemin, file.path(sortie, table$file), overwrite = TRUE))
}
tarifs <- read_csv(file.path(sortie, "tarifs.csv"), show_col_types = FALSE)
faits <- read_csv(file.path(sortie, "faits.csv"), show_col_types = FALSE)
preuves <- read_csv(file.path(sortie, "preuves.csv"), show_col_types = FALSE)
sources <- read_csv(file.path(sortie, "sources.csv"), show_col_types = FALSE)
stopifnot(nrow(tarifs) == 108, !anyDuplicated(tarifs$tarif_id),
  all(tarifs$montant_min >= 0), all(tarifs$montant_max >= tarifs$montant_min),
  !anyDuplicated(preuves$preuve_id), all(tarifs$preuve_id %in% preuves$preuve_id),
  all(na.omit(faits$preuve_id) %in% preuves$preuve_id),
  all(preuves$source_id %in% sources$source_id))
sources_manifest <- map(seq_len(nrow(sources)), function(i) list(
  source_id = sources$source_id[[i]], source_url = sources$url[[i]],
  acquisition_kind = "transcription_de_source_publique_archivee",
  acquired_at_utc = sources$retrieved_at[[i]], sha256 = sources$sha256[[i]]))
manifest_preparation <- list(dataset_id = id, prepared_at_utc = manifest$prepared_at_utc,
  version = version, r_version = as.character(getRversion()),
  script_sha256 = digest(file = file.path("datasets", id, "preparation.R"), algo = "sha256"),
  acquisition_mode = "compilation_figee_relue", sources = sources_manifest,
  tables = manifest$tables)
write_json(manifest_preparation, file.path(sortie, "manifest.json"), auto_unbox = TRUE, pretty = TRUE)
message("Pilote 2026 préparé : 10 programmes, 108 tarifs; observations et inconnues conservées.")
