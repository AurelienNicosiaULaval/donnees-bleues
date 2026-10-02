# Vérifier le paquet publié, ses ressources et ses empreintes.
library(jsonlite)
library(digest)
library(zip)

destination <- "docs/outils/maisons-quebec"
app <- read_json(file.path(destination, "app.json"))
app_names <- vapply(app, function(file) file$name, character(1))
stopifnot(!anyDuplicated(app_names),
  all(c("app.R", "R/helpers.R", "www/explorer.css", "www/maisons-quebec.webp",
        "data/maisons-quebec.csv", "DATA_LICENSES.md") %in% app_names),
  !any(grepl("rsconnect|\\.Renviron|check-server", app_names)))
for (file in app) {
  source <- file.path("applications/explorer-maisons-quebec", file$name)
  content <- if (isTRUE(file$type == "binary")) jsonlite::base64_dec(file$content) else
    charToRaw(enc2utf8(file$content))
  reference <- readBin(source, "raw", n = file.size(source))
  stopifnot(identical(content, reference))
}
index <- paste(readLines(file.path(destination, "index.html")), collapse = "\n")
stopifnot(grepl('lang="fr"', index, fixed = TRUE),
          grepl("runExportedApp", index, fixed = TRUE),
          file.exists(file.path(destination, "shinylive/shinylive.js")),
          file.exists(file.path(destination, "shinylive/webr/R.wasm")))
receipt <- read_json(file.path(destination, "publication.json"))
for (file in receipt$files) {
  path <- file.path(destination, file$path)
  stopifnot(file.exists(path), file.size(path) == file$bytes,
    digest(file = path, algo = "sha256") == file$sha256)
}
tools_receipt <- read_json("assets/tools/explorer-maisons-quebec.json")
stopifnot(digest(file = "assets/tools/explorer-maisons-quebec.zip", algo = "sha256") ==
  tools_receipt$archive_sha256)
temporary <- tempfile("house-zip-")
dir.create(temporary)
zip::unzip("assets/tools/explorer-maisons-quebec.zip", exdir = temporary)
for (file in tools_receipt$files) {
  stopifnot(digest(file = file.path(temporary, file$path), algo = "sha256") == file$sha256)
}
unlink(temporary, recursive = TRUE)
cat("Paquet Shinylive, ressources et application téléchargeable : empreintes vérifiées.\n")
