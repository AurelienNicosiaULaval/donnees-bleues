# Contrôler les CSV figés avant de préparer la trousse pédagogique.
# La reconstruction depuis les classeurs se trouve dans l'archive complète.
library(readr)
library(jsonlite)
library(digest)

id <- "caribous-riviere-aux-feuilles"
entree <- file.path("datasets", id, "downloads", "20261008")
sortie <- file.path("data/processed", id)
dir.create(sortie, recursive = TRUE, showWarnings = FALSE)
manifest <- read_json(file.path(entree, "manifest_publication.json"))
for (table in manifest$tables) {
  chemin <- file.path(entree, table$file)
  stopifnot(digest(file = chemin, algo = "sha256") == table$sha256)
  donnees <- read_csv(chemin, col_types = cols(.default = col_character()), show_col_types = FALSE)
  stopifnot(nrow(donnees) == table$rows, identical(names(donnees), unlist(table$columns)))
  stopifnot(file.copy(chemin, file.path(sortie, table$file), overwrite = TRUE))
}
provenance <- read_json(file.path(entree, "provenance.json"))
manifest$sources <- lapply(provenance$fichiers, function(f) list(
  source_url = f$url, acquisition_kind = "copie_publique_empreinte_Dryad_verifiee",
  acquired_at_utc = f$acquisition_utc, sha256 = f$sha256))
write_json(manifest, file.path(sortie, "manifest.json"), auto_unbox = TRUE, pretty = TRUE)
message("Caribous : six CSV contrôlés; trois tables pour la trousse pédagogique.")
