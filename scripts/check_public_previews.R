library(readr)
library(yaml)
source("R/utils_publication.R")
paths <- list.files("datasets", pattern = "metadata.yml$", recursive = TRUE, full.names = TRUE)
for (path in paths) {
  metadata <- read_yaml(path)
  validate_public_preview(metadata)
  if (isTRUE(metadata$publication$preview)) {
    file <- preview_path(metadata)
    receipt <- jsonlite::read_json(paste0(file, ".json"))
    if (!identical(receipt$preview_sha256, digest::digest(file = file, algo = "sha256"))) {
      stop("L'extrait a changé sans mettre à jour son manifeste : ", metadata$id, call. = FALSE)
    }
  }
}
message("Aperçus conformes aux décisions, colonnes et empreintes déclarées. Ce contrôle ne certifie pas l'anonymisation.")
