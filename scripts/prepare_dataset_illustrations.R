# Encode the approved PNG masters for the website, without cropping.
# Usage: Rscript scripts/prepare_dataset_illustrations.R /path/to/masters
library(magick)
library(readr)
library(jsonlite)
library(digest)

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1L) stop("Indiquer le dossier des illustrations PNG originales.")
catalogue <- read_csv("data/metadata/catalogue.csv", show_col_types = FALSE)
source_paths <- file.path(args[[1]], paste0(catalogue$id, ".png"))
if (!all(file.exists(source_paths))) {
  stop("Illustrations manquantes : ", paste(catalogue$id[!file.exists(source_paths)], collapse = ", "))
}
output_dir <- "assets/illustrations/datasets"
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

records <- lapply(seq_len(nrow(catalogue)), function(i) {
  picture <- image_read(source_paths[[i]])
  original <- image_info(picture)
  stopifnot(nrow(original) == 1L, abs(original$width / original$height - 16 / 9) < 0.01)
  picture <- image_strip(image_resize(picture, "960x"))
  target <- file.path(output_dir, paste0(catalogue$id[[i]], ".webp"))
  image_write(picture, target, format = "webp", quality = 82)
  info <- image_info(image_read(target))
  stopifnot(info$width == 960L, info$height == 540L, file.size(target) < 250000)
  list(id = catalogue$id[[i]], file = basename(target), width = info$width,
       height = info$height, bytes = file.size(target),
       sha256 = digest(file = target, algo = "sha256"),
       original_sha256 = digest(file = source_paths[[i]], algo = "sha256"))
})
write_json(records, file.path(output_dir, "manifest.json"), auto_unbox = TRUE, pretty = TRUE)
cat(length(records), "illustrations préparées,", round(sum(vapply(records, `[[`, numeric(1), "bytes")) / 1e6, 2), "Mo au total.\n")
