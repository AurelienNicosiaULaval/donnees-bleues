# Exporter uniquement le paquet public après le rendu Quarto.
library(shinylive)
library(jsonlite)
library(digest)
app_dir <- "applications/permutations-accidents-quebec"
files <- sort(setdiff(list.files(app_dir, recursive = TRUE), "check-server.R"))
stage <- tempfile("permutation-app-")
dir.create(stage)
for (path in files) {
  destination <- file.path(stage, path)
  dir.create(dirname(destination), recursive = TRUE, showWarnings = FALSE)
  stopifnot(file.copy(file.path(app_dir, path), destination))
}
destination <- "docs/outils/permutations-accidents"
shinylive::export(stage, destination, assets_version = "0.10.12")
unlink(stage, recursive = TRUE)
index <- file.path(destination, "index.html")
html <- paste(readLines(index, warn = FALSE), collapse = "\n")
html <- sub('lang="en"', 'lang="fr"', html, fixed = TRUE)
html <- sub("<title>Shiny App</title>",
  "<title>Accidents au Québec : comparer par permutation | Données bleues</title>", html, fixed = TRUE)
writeLines(html, index, useBytes = TRUE)
source("R/utils_seo.R")
postprocess_site_seo("docs", paste0(sub("^docs/", "", destination), "/",
  list.files(destination, pattern = "[.]html$", recursive = TRUE)))
files <- setdiff(list.files(destination, recursive = TRUE, full.names = TRUE),
                 file.path(destination, "publication.json"))
write_json(list(app_version = "1.0.0", assets_version = "0.10.12",
  shinylive_version = as.character(packageVersion("shinylive")),
  files = lapply(files, function(path) list(path = substring(path, nchar(destination) + 2L),
    bytes = unname(file.size(path)), sha256 = digest(file = path, algo = "sha256")))),
  file.path(destination, "publication.json"), auto_unbox = TRUE, pretty = TRUE)
cat("Application de permutation exportée pour le navigateur.\n")
