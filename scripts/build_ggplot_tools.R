# Build the downloadable application from an explicit public-file inventory.
library(zip)
library(jsonlite)
library(digest)

app_dir <- "applications/ggplot-builder-donnees-bleues"
files <- c("app.R", "R/builder.R", "www/builder.css", "www/builder.js",
  "www/favicon.svg", "data/arbres_quebec.csv", "DATA_LICENSES.md", "LICENSE",
  "LICENCE-CONTENUS.md", "README.md", "INSTALLER.R", "LANCER.R",
  "verifier.R", "exemple-graphique.R")
stopifnot(all(file.exists(file.path(app_dir, files))))
dir.create("assets/tools", recursive = TRUE, showWarnings = FALSE)
archive <- file.path(normalizePath("assets/tools"), "ggplot-builder-donnees-bleues.zip")
if (file.exists(archive)) unlink(archive)
zip::zipr(archive, files, root = app_dir, include_directories = FALSE, mode = "mirror")
stopifnot(file.copy(file.path(app_dir, "exemple-graphique.R"),
  "assets/tools/ggplot-builder-exemple.R", overwrite = TRUE))
receipt <- list(version = "1.0.0", dataset = "arbres-quebec",
  dataset_sha256 = digest(file = file.path(app_dir, "data/arbres_quebec.csv"), algo = "sha256"),
  files = lapply(files, function(path) list(path = path,
    sha256 = digest(file = file.path(app_dir, path), algo = "sha256"))),
  archive_sha256 = digest(file = archive, algo = "sha256"))
write_json(receipt, "assets/tools/ggplot-builder-donnees-bleues.json", auto_unbox = TRUE, pretty = TRUE)
cat("Application ggplot builder et exemple R téléchargeables construits.\n")
