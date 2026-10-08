# Vérifier les fichiers publics et les originaux conservés dans l'archive.
library(readr)
library(jsonlite)
library(digest)

local({
  dossier <- "datasets/caribous-riviere-aux-feuilles/downloads/20261008"
  manifest <- read_json(file.path(dossier, "manifest_publication.json"))
  for (f in manifest$files) {
    chemin <- file.path(dossier, f$file)
    stopifnot(file.exists(chemin), file.size(chemin) == f$bytes,
              digest(file = chemin, algo = "sha256") == f$sha256)
  }
  for (t in manifest$tables) {
    donnees <- read_csv(file.path(dossier, t$file),
      col_types = cols(.default = col_character()), show_col_types = FALSE)
    stopifnot(nrow(donnees) == t$rows, identical(names(donnees), unlist(t$columns)))
  }
  archive <- file.path(dossier, "caribous-reproduction-20261008.zip")
  chemins <- unzip(archive, list = TRUE)$Name
  stopifnot(!any(grepl("(^/|(^|/)\\.\\.(/|$))", chemins)))
  stage <- tempfile("caribous-reproduction-")
  dir.create(stage)
  on.exit(unlink(stage, recursive = TRUE), add = TRUE)
  unzip(archive, exdir = stage)
  empreintes <- read_csv(file.path(stage, "manifest_sha256.csv"), show_col_types = FALSE)
  for (i in seq_len(nrow(empreintes))) {
    stopifnot(digest(file = file.path(stage, empreintes$fichier[i]), algo = "sha256") == empreintes$sha256[i])
  }
  provenance <- read_json(file.path(stage, "provenance.json"))
  stopifnot(length(provenance$fichiers) == 6L)
  for (f in provenance$fichiers) {
    original <- file.path(stage, "donnees_originales", f$fichier)
    stopifnot(digest(file = original, algo = "md5") == f$md5,
      digest(file = original, algo = "sha256") == f$sha256,
      isTRUE(f$correspondance_md5_dryad))
  }
  for (t in manifest$tables) {
    stopifnot(digest(file = file.path(stage, "donnees_preparees", t$file), algo = "sha256") == t$sha256)
  }
  # L'iframe doit rester une ressource servie, afin d'envoyer un Referer valide
  # aux tuiles OpenStreetMap; une URL data: n'a pas cette propriété.
  fiche <- paste(readLines("datasets/caribous-riviere-aux-feuilles/fiche.qmd"), collapse = "\n")
  stopifnot(grepl('src="downloads/20261008/carte.htm" data-external="1"', fiche, fixed = TRUE))
  carte <- paste(readLines(file.path(dossier, "carte.htm")), collapse = "\n")
  stopifnot(grepl("https://tile.openstreetmap.org/{z}/{x}/{y}.png", carte, fixed = TRUE),
            grepl("https://www.openstreetmap.org/copyright", carte, fixed = TRUE))
  cat("Caribous : archives, six originaux, six CSV et carte vérifiés.\n")
})
