# Usage : Rscript scripts/prepare_datasets.R bixi qualite-air
#         Rscript scripts/prepare_datasets.R --all
# DB_OFFLINE=true réutilise les sources conservées et contrôle leurs empreintes.
args <- commandArgs(trailingOnly = TRUE)
scripts <- sort(list.files("datasets", pattern = "^preparation[.]R$", recursive = TRUE, full.names = TRUE))
ids <- basename(dirname(scripts))
if (!length(args)) stop("Indiquer un identifiant de jeu ou --all.", call. = FALSE)
if (!identical(args, "--all")) {
  if (length(setdiff(args, ids))) stop("Jeu inconnu : ", paste(setdiff(args, ids), collapse = ", "), call. = FALSE)
  scripts <- scripts[ids %in% args]
}
dir.create("data/validation/imports", recursive = TRUE, showWarnings = FALSE)
results <- lapply(scripts, function(script) {
  id <- basename(dirname(script))
  log <- file.path("data/validation/imports", paste0(id, ".log"))
  started <- format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
  status <- system2(file.path(R.home("bin"), "Rscript"), shQuote(script), stdout = log, stderr = log, timeout = 1200)
  scope <- switch(id, `ulaval-programmes-cours` = "Métadonnées et contrôles disponibles; la disponibilité de la source privée est indiquée dans le journal",
                  `retards-transport-collectif` = "Métadonnées et dictionnaire; aucune observation de retard STM collectée",
                  "Données de la source déclarée préparées")
  message(id, " : ", if (status == 0L) "terminé" else "échec", " (", scope, ")")
  list(dataset_id = id, started_at_utc = started, exit_code = status, scope = scope, log = log)
})
jsonlite::write_json(results, "data/validation/imports/results.json", auto_unbox = TRUE, pretty = TRUE)
if (any(vapply(results, function(x) x$exit_code != 0L, logical(1)))) stop("Au moins une préparation a échoué; consulter data/validation/imports/.", call. = FALSE)
