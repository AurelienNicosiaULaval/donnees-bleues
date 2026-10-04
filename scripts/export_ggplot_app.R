# Export only the public runtime files, preserving the existing house export.
library(shinylive)
library(jsonlite)
library(digest)

app_dir <- "applications/ggplot-builder-donnees-bleues"
files <- c("app.R", "R/builder.R", "www/builder.css", "www/builder.js",
  "www/favicon.svg", "data/arbres_quebec.csv", "DATA_LICENSES.md", "LICENSE",
  "LICENCE-CONTENUS.md", "README.md")
stage <- tempfile("ggplot-app-")
dir.create(stage)
for (path in files) {
  destination <- file.path(stage, path)
  dir.create(dirname(destination), recursive = TRUE, showWarnings = FALSE)
  stopifnot(file.copy(file.path(app_dir, path), destination))
}
destination <- "docs/outils/ggplot-builder"
shinylive::export(stage, destination, assets_version = "0.10.12")
unlink(stage, recursive = TRUE)
# Preserve the CSV bytes when Shinylive writes files into R's virtual filesystem.
# Its text writer adds a newline, so ship this source file as a binary asset.
app_path <- file.path(destination, "app.json")
app <- read_json(app_path)
for (i in seq_along(app)) {
  if (app[[i]]$name == "data/arbres_quebec.csv") {
    csv_path <- file.path(app_dir, app[[i]]$name)
    app[[i]]$type <- "binary"
    app[[i]]$content <- base64_enc(readBin(csv_path, "raw", n = file.size(csv_path)))
  }
}
write_json(app, app_path, auto_unbox = TRUE)
index <- file.path(destination, "index.html")
html <- paste(readLines(index, warn = FALSE), collapse = "\n")
html <- sub('lang="en"', 'lang="fr"', html, fixed = TRUE)
html <- sub("<title>Shiny App</title>", "<title>ggplot builder | Données bleues</title>", html, fixed = TRUE)
html <- sub("</head>", '<link rel="icon" type="image/svg+xml" href="favicon.svg">\n</head>', html, fixed = TRUE)
writeLines(html, index, useBytes = TRUE)
source("R/utils_seo.R")
postprocess_site_seo("docs", paste0(sub("^docs/", "", destination), "/",
  list.files(destination, pattern = "[.]html$", recursive = TRUE)))
stopifnot(file.copy(file.path(app_dir, "www/favicon.svg"),
  file.path(destination, "favicon.svg"), overwrite = TRUE))
files <- list.files(destination, recursive = TRUE, full.names = TRUE)
files <- files[basename(files) != "publication.json"]
receipt <- list(shinylive_version = as.character(packageVersion("shinylive")),
  assets_version = "0.10.12", app_version = "1.0.0",
  files = lapply(files, function(path) list(path = substring(path, nchar(destination) + 2L),
    bytes = unname(file.size(path)), sha256 = digest(file = path, algo = "sha256"))))
write_json(receipt, file.path(destination, "publication.json"), auto_unbox = TRUE, pretty = TRUE)
cat("Export Shinylive du ggplot builder construit :", length(files), "fichiers.\n")
