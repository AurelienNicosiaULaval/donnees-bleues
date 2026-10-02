# Construire les téléchargements à partir des sources contrôlées.
library(knitr)
library(zip)
library(jsonlite)
library(digest)

app_dir <- "applications/explorer-maisons-quebec"
files <- c("app.R", "R/helpers.R", "www/explorer.css", "www/maisons-quebec.webp",
           "data/maisons-quebec.csv", "DATA_LICENSES.md", "DICTIONNAIRE.md",
           "METHODE.md", "LICENSE", "LICENCE-CONTENUS.md", "README.md",
           "check-server.R")
stopifnot(all(file.exists(file.path(app_dir, files))))
dir.create("assets/tools", recursive = TRUE, showWarnings = FALSE)
knitr::purl("resources/tutoriel-maisons-quebec.qmd",
            output = "assets/tools/tutoriel-maisons-quebec.R",
            documentation = 0, quiet = TRUE)
# La notice Quarto est le seul bloc spécifique au site.
script <- readLines("assets/tools/tutoriel-maisons-quebec.R", warn = FALSE)
script <- script[!grepl("utils_resources.R|render_resource_notice_identity", script)]
writeLines(c("# Données bleues : tutoriel Maisons à Québec",
  "# Aurélien Nicosia (2026). Code MIT; données MAMH et contenus CC BY 4.0.",
  "# Valeurs au rôle 2025, référence au marché 2023-07-01, extraction 2026.",
  script), "assets/tools/tutoriel-maisons-quebec.R", useBytes = TRUE)

archive <- file.path(normalizePath("assets/tools", mustWork = TRUE), "explorer-maisons-quebec.zip")
if (file.exists(archive)) unlink(archive)
zip::zipr(archive, files, root = app_dir, include_directories = FALSE, mode = "mirror")
receipt <- list(version = "1.0.0", dataset = "maisons-quebec",
  dataset_sha256 = digest(file = file.path(app_dir, "data/maisons-quebec.csv"), algo = "sha256"),
  files = lapply(files, function(path) list(path = path,
    sha256 = digest(file = file.path(app_dir, path), algo = "sha256"))),
  archive_sha256 = digest(file = archive, algo = "sha256"),
  tutorial_sha256 = digest(file = "assets/tools/tutoriel-maisons-quebec.R", algo = "sha256"))
write_json(receipt, "assets/tools/explorer-maisons-quebec.json",
           auto_unbox = TRUE, pretty = TRUE)
cat("Application complète et script du tutoriel construits.\n")
