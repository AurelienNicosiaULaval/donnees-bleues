# Vérifier et préparer l'édition figée, sans connexion réseau.
library(readr)
library(dplyr)
library(jsonlite)
library(digest)

id <- "tarifs-douaniers-quebec"
version <- "20261005T200817Z"
entree <- file.path("datasets", id, "downloads", version)
sortie <- file.path("data/processed", id)
manifest <- read_json(file.path(entree, "manifest_publication.json"))
dir.create(sortie, recursive = TRUE, showWarnings = FALSE)
for (table in manifest$tables) {
  chemin <- file.path(entree, table$file)
  stopifnot(digest(file = chemin, algo = "sha256") == table$sha256)
  d <- read_csv(chemin, col_types = cols(.default = col_character()), show_col_types = FALSE)
  stopifnot(nrow(d) == table$rows, identical(names(d), unlist(table$columns)))
  stopifnot(file.copy(chemin, file.path(sortie, table$file), overwrite = TRUE))
}
actuels <- read_csv(file.path(sortie, "contre_tarifs_20260908.csv"), col_types = cols(.default = col_character()), show_col_types = FALSE)
annexes <- read_csv(file.path(sortie, "annexes_2026.csv"), col_types = cols(.default = col_character()), show_col_types = FALSE)
stopifnot(nrow(actuels) == 648L, nrow(annexes) == 335L,
 !anyDuplicated(actuels$code_tarifaire), all(grepl("^[0-9]{8}$", actuels$code_tarifaire)))
rapprochement <- left_join(annexes, actuels |> select(code_tarifaire, taux_liste = taux_surtaxe_pourcent), by = "code_tarifaire")
stopifnot(!anyNA(rapprochement$taux_liste), all(rapprochement$taux_surtaxe_pourcent == rapprochement$taux_liste))
captures <- read_csv(file.path(sortie, "captures_sources.csv"), col_types = cols(.default = col_character()), show_col_types = FALSE)
preuves <- lapply(seq_len(nrow(captures)), function(i) list(source_id = captures$source_id[i],
 source_url = captures$url[i], acquired_at_utc = captures$observed_at_utc[i],
 sha256 = captures$sha256[i], acquisition_kind = captures$methode[i]))
write_json(list(dataset_id = id, prepared_at_utc = manifest$prepared_at_utc,
 version = version, r_version = as.character(getRversion()), acquisition_mode = "edition_figee_verifiee",
 script_sha256 = digest(file = file.path("datasets", id, "preparation.R"), algo = "sha256"),
 sources = preuves, tables = manifest$tables), file.path(sortie, "manifest.json"), auto_unbox = TRUE, pretty = TRUE)
message("Édition préparée et empreintes vérifiées : ", version)
