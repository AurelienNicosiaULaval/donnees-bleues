library(readr)
library(yaml)

`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0L || all(is.na(x))) y else x
}

license_blocks_preview <- function(license) {
  grepl(
    "reproduction.*interdite|aucune licence ouverte|réutilisation publique à valider",
    tolower(as.character(license %||% ""))
  )
}

metadata_paths <- list.files("datasets", pattern = "metadata.yml$", recursive = TRUE, full.names = TRUE)
protected_columns <- "adresse|address|adrs|rue|street|civique|postl|postal|courriel|email|telephone|phone|longitude|latitude|(^lat$)|(^lon$)|coord|geom|mtm|(^x$)|(^y$)|(^x_)|(^y_)|site_web|source.*url|nom_exploitant|raison_sociale|nom_intervenant"

for (metadata_path in metadata_paths) {
  metadata <- read_yaml(metadata_path)
  id <- as.character(metadata$id %||% basename(dirname(metadata_path)))
  preview_path <- as.character(
    metadata$preview_file %||% file.path("assets", "previews", paste0(id, ".csv"))
  )
  restricted <- license_blocks_preview(metadata$license)

  if (restricted) {
    if (file.exists(preview_path)) {
      stop("Un aperçu public est interdit pour ", id, call. = FALSE)
    }
    next
  }

  if (!file.exists(preview_path)) {
    stop("Aperçu public manquant pour ", id, " : ", preview_path, call. = FALSE)
  }

  preview <- read_csv(preview_path, show_col_types = FALSE)
  if (nrow(preview) < 2L || nrow(preview) > 120L || ncol(preview) == 0L) {
    stop("Aperçu public invalide pour ", id, call. = FALSE)
  }
  if (any(grepl(protected_columns, names(preview), ignore.case = TRUE))) {
    stop("Colonne protégée détectée dans l'aperçu public de ", id, call. = FALSE)
  }
}

message("Tous les aperçus publics requis sont présents et sûrs.")
