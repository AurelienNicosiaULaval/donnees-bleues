library(jsonlite)
library(digest)
source("R/utils_classroom.R")
app_dir <- "applications/bootstrap-maisons-quebec"
destination <- "docs/outils/bootstrap-maisons"
app <- read_json(file.path(destination, "app.json"))
names <- vapply(app, function(x) x$name, character(1))
stopifnot(!anyDuplicated(names),
  all(c("app.R", "R/bootstrap.R", "data/maisons-quebec.csv", "www/bootstrap.css") %in% names),
  !any(grepl("rsconnect|[.]Renviron|check-server", names)))
for (file in app) {
  reference <- file.path(app_dir, file$name)
  raw <- if (isTRUE(file$type == "binary")) base64_dec(file$content) else charToRaw(enc2utf8(file$content))
  stopifnot(identical(raw, readBin(reference, "raw", n = file.size(reference))))
}
index <- paste(readLines(file.path(destination, "index.html")), collapse = "\n")
stopifnot(grepl('lang="fr"', index, fixed = TRUE),
  grepl("Bootstrap des maisons", index, fixed = TRUE),
  file.exists(file.path(destination, "shinylive/webr/R.wasm")))
for (file in read_json(file.path(destination, "publication.json"))$files) {
  path <- file.path(destination, file$path)
  stopifnot(file.size(path) == file$bytes, classroom_sha(path) == file$sha256)
}
receipt <- read_json("assets/tools/bootstrap-maisons-quebec.json")
stopifnot(classroom_sha("assets/tools/bootstrap-maisons-quebec.zip") == receipt$archive_sha256,
  classroom_sha("assets/data/maisons-quebec.csv") == receipt$dataset_sha256)
stage <- tempfile("bootstrap-zip-")
dir.create(stage)
utils::unzip("assets/tools/bootstrap-maisons-quebec.zip", exdir = stage)
for (file in receipt$files)
  stopifnot(classroom_sha(file.path(stage, file$path)) == file$sha256,
    classroom_sha(file.path(app_dir, file$path)) == file$sha256)
unlink(stage, recursive = TRUE)
cat("Export navigateur et téléchargement bootstrap : contenu et empreintes vérifiés.\n")
