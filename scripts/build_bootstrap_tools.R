# Construire le moteur de l’application depuis le script autonome de classe.
library(zip)
library(jsonlite)
library(digest)
library(yaml)
source("R/utils_classroom.R")

app_dir <- "applications/bootstrap-maisons-quebec"
script <- readLines("datasets/maisons-quebec/activite-bootstrap.R", warn = FALSE, encoding = "UTF-8")
marker <- grep("^# ACTIVITÉ :", script)
stopifnot(length(marker) == 1L)
dir.create(file.path(app_dir, "R"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(app_dir, "data"), recursive = TRUE, showWarnings = FALSE)
engine <- script[seq_len(marker - 1L)]
while (length(engine) && !nzchar(tail(engine, 1L))) engine <- head(engine, -1L)
writeLines(engine, file.path(app_dir, "R/bootstrap.R"), useBytes = TRUE)
stopifnot(file.copy("assets/data/maisons-quebec.csv", file.path(app_dir, "data/maisons-quebec.csv"), overwrite = TRUE))
for (name in c("DATA_LICENSES.md", "DICTIONNAIRE.md", "METHODE.md"))
  stopifnot(file.copy(file.path("datasets/maisons-quebec", name), file.path(app_dir, name), overwrite = TRUE))
for (name in c("LICENSE", "LICENCE-CONTENUS.md"))
  stopifnot(file.copy(name, file.path(app_dir, name), overwrite = TRUE))
stopifnot(file.copy("assets/illustrations/datasets/maisons-quebec.webp",
  file.path(app_dir, "www/maisons-quebec.webp"), overwrite = TRUE))
dir.create("assets/tools", recursive = TRUE, showWarnings = FALSE)
stopifnot(file.copy("datasets/maisons-quebec/activite-bootstrap.R",
  "assets/tools/bootstrap-maisons-quebec.R", overwrite = TRUE))
files <- sort(list.files(app_dir, recursive = TRUE))
stopifnot(!any(grepl("rsconnect|[.]Renviron|[.]Rhistory", files)))
archive <- file.path(normalizePath("assets/tools"), "bootstrap-maisons-quebec.zip")
if (file.exists(archive)) unlink(archive)
Sys.setFileTime(file.path(app_dir, files), as.POSIXct("2000-01-01", tz = "UTC"))
zip::zipr(archive, files, root = app_dir, include_directories = FALSE, mode = "mirror")
write_json(list(version = "1.0.0", dataset = "maisons-quebec", dataset_version = "1.0.0",
  dataset_sha256 = classroom_sha(file.path(app_dir, "data/maisons-quebec.csv")),
  archive_sha256 = classroom_sha(archive),
  files = lapply(files, function(path) list(path = path, sha256 = classroom_sha(file.path(app_dir, path))))),
  "assets/tools/bootstrap-maisons-quebec.json", auto_unbox = TRUE, pretty = TRUE)
# Les sources préparées locales sont facultatives en CI : la trousse et le
# script sont versionnés et vérifiés; aucun téléchargement de données ajouté.
if (file.exists("data/processed/maisons-quebec/manifest.json"))
  build_classroom_kit(read_yaml("datasets/maisons-quebec/metadata.yml"))
cat("Moteur commun, application téléchargeable et script autonome construits.\n")
