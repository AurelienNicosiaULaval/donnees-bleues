# Vérification de l'artefact distribué, depuis la racine du dépôt.
# Les activités sont exécutées dans deux processus isolés où le téléchargement est interdit.
library(readr)
library(dplyr)
library(yaml)
library(digest)
library(jsonlite)
source("R/utils_classroom.R")

id <- "maisons-quebec"
metadata <- read_yaml(file.path("datasets", id, "metadata.yml"))
archive <- file.path("assets/classroom", paste0(id, ".zip"))
receipt <- read_json(paste0(archive, ".json"), simplifyVector = TRUE)
stopifnot(classroom_sha(archive) == receipt$archive_sha256)
stage <- tempfile("maisons-verification-")
dir.create(stage)
utils::unzip(archive, exdir = stage)
entries <- utils::unzip(archive, list = TRUE)$Name
stopifnot(!any(grepl("(^/|(^|/)\\.\\.(/|$))", entries)))
for (line in readLines(file.path(stage, "SHA256SUMS"))) {
  stopifnot(classroom_sha(file.path(stage, substring(line, 67))) == substr(line, 1, 64))
}
allowed <- vapply(metadata$publication$classroom$files, function(x) x$path, character(1))
stopifnot(setequal(entries[grepl("[.]csv$", entries)], allowed))
for (file in allowed) {
  published <- read_csv(file.path(stage, file), col_types = cols(.default = col_character()),
                        show_col_types = FALSE)
  prepared <- read_csv(file, col_types = cols(.default = col_character()), show_col_types = FALSE)
  stopifnot(identical(names(published), names(prepared)),
    all(vapply(names(prepared), function(name) identical(published[[name]], prepared[[name]]), logical(1))),
    nrow(published) == 600L, ncol(published) == 19L)
}
stopifnot(classroom_sha(metadata$processed_file) == classroom_sha("assets/data/maisons-quebec.csv"))
provenance <- read_csv("data/processed/maisons-quebec/provenance_lignes.csv", show_col_types = FALSE)
maisons <- read_csv(metadata$processed_file, show_col_types = FALSE)
stopifnot(identical(provenance$maison_id, maisons$maison_id),
  !anyDuplicated(provenance$ligne_source), all(abs(provenance$probabilite_inclusion - 600 / 99072) < 1e-15),
  all(maisons$valeur_fonciere_cad == maisons$valeur_terrain_cad + maisons$valeur_batiment_cad))

root <- normalizePath(".")
output <- file.path(root, "data/validation/maisons-quebec")
dir.create(output, recursive = TRUE, showWarnings = FALSE)
results <- list()
for (script in classroom_script_paths(id)) {
  stopifnot(classroom_sha(script) == classroom_sha(file.path(stage, script)))
  directory <- file.path(output, tools::file_path_sans_ext(basename(script)))
  dir.create(directory, recursive = TRUE, showWarnings = FALSE)
  arguments <- c("--vanilla", vapply(c(file.path(root, "scripts/run_activity.R"),
    file.path(stage, script), directory, stage), shQuote, character(1)))
  status <- system2(file.path(R.home("bin"), "Rscript"), arguments,
    stdout = file.path(directory, "run.log"), stderr = file.path(directory, "run.log"))
  result <- read_json(file.path(directory, "result.json"), simplifyVector = TRUE)
  stopifnot(status == 0L, result$status == "ok", result$plots >= 2L)
  results[[basename(script)]] <- result
}
# Relire les sorties du processus de la trousse, y compris la séparation réelle et la CV.
split <- read_csv(file.path(stage, "outputs/maisons-partage.csv"),
  col_types = cols(.default = col_character()), show_col_types = FALSE)
stopifnot(!length(intersect(split$voisinage_code[split$ensemble == "Test"],
  split$voisinage_code[split$ensemble == "Apprentissage"])),
  sum(split$ensemble == "Test") == 100L, sum(split$ensemble == "Apprentissage") == 500L)
cv <- read_csv(file.path(stage, "outputs/maisons-predictions-cv.csv"), show_col_types = FALSE)
predictions <- read_csv(file.path(stage, "outputs/maisons-predictions-test.csv"), show_col_types = FALSE)
stopifnot(nrow(cv) == 500L, !anyDuplicated(cv$maison_id), nrow(predictions) == 100L,
  !length(intersect(cv$maison_id, predictions$maison_id)),
  all(is.finite(cv$prediction_cad)), all(is.finite(predictions$regression_log)))
scores <- read_csv(file.path(stage, "outputs/maisons-scores-test.csv"), show_col_types = FALSE)
for (name in scores$modele) {
  error <- predictions[[name]] - predictions$observe_cad
  stopifnot(abs(scores$mae_cad[scores$modele == name] - mean(abs(error))) < 1e-8,
    abs(scores$rmse_cad[scores$modele == name] - sqrt(mean(error^2))) < 1e-8)
}
write_json(list(status = "ok", rows = 600L, columns = 19L,
  archive_sha256 = classroom_sha(archive), csv_sha256 = classroom_sha(metadata$processed_file),
  scripts = results, test_rows = 100L, training_rows = 500L, group_overlap = 0L),
  file.path(output, "verification.json"), auto_unbox = TRUE, pretty = TRUE)
unlink(stage, recursive = TRUE)
message("CSV, empreintes et deux scripts du ZIP vérifiés hors ligne; séparation et scores recalculés.")
