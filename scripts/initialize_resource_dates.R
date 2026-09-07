# One-time migration. Existing editorial dates are never changed by this script.
# Dates describe the resource in this repository, not collection or source publication.
library(yaml)
library(readr)

git_lines <- function(args) {
  result <- system2("git", vapply(args, shQuote, character(1)), stdout = TRUE)
  if (!is.null(attr(result, "status"))) stop("Historique Git indisponible.", call. = FALSE)
  result
}
history_dates <- function(paths) {
  paths <- paths[file.exists(paths)]
  added <- unlist(lapply(paths[grepl("[.](qmd|yml)$", paths)], function(path)
    git_lines(c("log", "--follow", "--diff-filter=A", "--format=%cI", "--", path))))
  updated <- git_lines(c("log", "-1", "--format=%cI", "--", paths))
  stopifnot(length(added) > 0L, length(updated) == 1L)
  c(date_added = min(substr(added, 1, 10)), date_updated = substr(updated, 1, 10))
}
provenance <- list()
paths <- list.files("datasets", pattern = "^(metadata|activite-.*)[.]yml$", recursive = TRUE, full.names = TRUE)
for (path in paths) {
  metadata <- read_yaml(path)
  if (!is.null(metadata$date_added) || !is.null(metadata$date_updated)) next
  dataset <- basename(path) == "metadata.yml"
  inputs <- if (dataset) c(path, file.path(dirname(path), c("fiche.qmd", "preparation.R", "DICTIONNAIRE.md")),
    paste0("assets/previews/", metadata$id, ".csv.json")) else c(path, sub("[.]yml$", ".qmd", path), sub("[.]yml$", ".R", path))
  dates <- history_dates(inputs)
  writeLines(c(readLines(path, warn = FALSE), paste0(names(dates), ': "', dates, '"')), path)
  provenance[[length(provenance) + 1L]] <- data.frame(id = metadata$id,
    type = if (dataset) "donnees" else "activite", t(dates), stringsAsFactors = FALSE)
}

# A change to another entry in the shared registry must not change this resource's date.
registry <- "data/metadata/ressources.yml"
items <- read_yaml(registry)
commits <- rev(git_lines(c("log", "--format=%H", "--", registry)))
last_state <- list(); item_updated <- list()
for (commit in commits) {
  historical <- yaml.load(paste(git_lines(c("show", paste0(commit, ":", registry))), collapse = "\n"))
  date <- substr(git_lines(c("show", "-s", "--format=%cI", commit)), 1, 10)
  for (item in historical) {
    if (!identical(item, last_state[[item$id]])) item_updated[[item$id]] <- date
    last_state[[item$id]] <- item
  }
}
lines <- readLines(registry, warn = FALSE)
for (item in items) {
  if (!is.null(item$date_added) || !is.null(item$date_updated)) next
  dates <- history_dates(paste0("resources/", item$id, ".qmd"))
  dates["date_updated"] <- max(dates["date_updated"], item_updated[[item$id]])
  at <- which(lines == paste0("- id: ", item$id)); stopifnot(length(at) == 1L)
  lines <- append(lines, paste0("  ", names(dates), ': "', dates, '"'), after = at)
  provenance[[length(provenance) + 1L]] <- data.frame(id = item$id, type = item$type, t(dates), stringsAsFactors = FALSE)
}
writeLines(lines, registry)
if (length(provenance)) write_csv(do.call(rbind, provenance), "data/metadata/resource_dates_initialization.csv")
message(length(provenance), " ressources datées d’après l’historique Git.")
