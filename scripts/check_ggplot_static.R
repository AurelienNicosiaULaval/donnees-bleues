# Compare the exported app and downloadable archive with the reviewed sources.
library(jsonlite)
library(digest)
library(zip)

destination <- "docs/outils/ggplot-builder"
app <- read_json(file.path(destination, "app.json"))
app_names <- vapply(app, function(file) file$name, character(1))
stopifnot(!anyDuplicated(app_names),
  all(c("app.R", "R/builder.R", "www/builder.css", "www/builder.js",
        "data/arbres_quebec.csv", "DATA_LICENSES.md") %in% app_names),
  !any(grepl("rsconnect|\\.Renviron|verifier[.]R|Rplots", app_names)))
stopifnot(app[[match("data/arbres_quebec.csv", app_names)]]$type == "binary")
for (file in app) {
  source <- file.path("applications/ggplot-builder-donnees-bleues", file$name)
  content <- if (isTRUE(file$type == "binary")) base64_dec(file$content) else charToRaw(enc2utf8(file$content))
  reference <- readBin(source, "raw", n = file.size(source))
  stopifnot(identical(content, reference))
}
index <- paste(readLines(file.path(destination, "index.html")), collapse = "\n")
stopifnot(grepl('lang="fr"', index, fixed = TRUE),
  grepl("ggplot builder | Données bleues", index, fixed = TRUE),
  grepl("runExportedApp", index, fixed = TRUE),
  file.exists(file.path(destination, "shinylive/webr/R.wasm")))
receipt <- read_json(file.path(destination, "publication.json"))
for (file in receipt$files) {
  path <- file.path(destination, file$path)
  stopifnot(file.exists(path), file.size(path) == file$bytes,
    digest(file = path, algo = "sha256") == file$sha256)
}
receipt <- read_json("assets/tools/ggplot-builder-donnees-bleues.json")
stopifnot(digest(file = "assets/tools/ggplot-builder-donnees-bleues.zip", algo = "sha256") == receipt$archive_sha256)
temporary <- tempfile("ggplot-zip-")
dir.create(temporary)
zip::unzip("assets/tools/ggplot-builder-donnees-bleues.zip", exdir = temporary)
for (file in receipt$files) {
  stopifnot(digest(file = file.path(temporary, file$path), algo = "sha256") == file$sha256)
}
unlink(temporary, recursive = TRUE)
cat("ggplot builder : export, ressources et archive vérifiés par empreintes.\n")
