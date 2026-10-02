# Exporter les seuls fichiers publics de l'application après le rendu du site.
library(shinylive)
library(jsonlite)
library(digest)

app_dir <- "applications/explorer-maisons-quebec"
files <- c("app.R", "R/helpers.R", "www/explorer.css", "www/maisons-quebec.webp",
           "data/maisons-quebec.csv", "DATA_LICENSES.md", "DICTIONNAIRE.md",
           "METHODE.md", "LICENSE", "LICENCE-CONTENUS.md", "README.md")
stage <- tempfile("house-app-")
dir.create(stage)
for (path in files) {
  destination <- file.path(stage, path)
  dir.create(dirname(destination), recursive = TRUE, showWarnings = FALSE)
  stopifnot(file.copy(file.path(app_dir, path), destination))
}
destination <- "docs/outils/maisons-quebec"
shinylive::export(stage, destination, assets_version = "0.10.12")
unlink(stage, recursive = TRUE)
# Le titre et la langue du conteneur sont explicites, sans modifier le moteur.
index <- file.path(destination, "index.html")
html <- paste(readLines(index, warn = FALSE), collapse = "\n")
html <- sub('lang="en"', 'lang="fr"', html, fixed = TRUE)
html <- sub("<title>Shiny App</title>",
            "<title>Explorer les maisons à Québec | Données bleues</title>",
            html, fixed = TRUE)
writeLines(html, index, useBytes = TRUE)
files <- list.files(destination, recursive = TRUE, full.names = TRUE)
receipt <- list(shinylive_version = as.character(packageVersion("shinylive")),
  assets_version = "0.10.12", app_version = "1.0.0",
  files = lapply(files, function(path) list(
    path = substring(path, nchar(destination) + 2L),
    bytes = unname(file.size(path)),
    sha256 = digest(file = path, algo = "sha256"))))
write_json(receipt, file.path(destination, "publication.json"),
           auto_unbox = TRUE, pretty = TRUE)
cat("Export Shinylive construit :", length(files), "fichiers.\n")
