`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0L || all(is.na(x))) y else x
}

read_dataset_metadata <- function(path) {
  if (!requireNamespace("yaml", quietly = TRUE)) {
    stop("Le package yaml est requis.", call. = FALSE)
  }

  metadata_path <- path
  if (dir.exists(path)) {
    metadata_path <- file.path(path, "metadata.yml")
  }

  if (!file.exists(metadata_path)) {
    stop("Fichier metadata.yml introuvable : ", metadata_path, call. = FALSE)
  }

  yaml::read_yaml(metadata_path)
}

metadata_zero_waste_score <- function(metadata) {
  if (is.null(metadata$zero_waste)) {
    return(NA_real_)
  }

  source("R/utils_zero_waste.R", local = TRUE)
  compute_zero_waste_score(metadata$zero_waste)$total
}

metadata_row <- function(metadata, dataset_dir) {
  concepts <- metadata$concepts %||% character()
  concepts <- paste(unlist(concepts), collapse = "; ")

  data.frame(
    id = metadata$id %||% basename(dataset_dir),
    title = metadata$title %||% NA_character_,
    short_title = metadata$short_title %||% NA_character_,
    theme = metadata$theme %||% NA_character_,
    source_name = metadata$source_name %||% NA_character_,
    source_url = metadata$source_url %||% NA_character_,
    license = metadata$license %||% NA_character_,
    access_date = metadata$access_date %||% NA_character_,
    geography = metadata$geography %||% NA_character_,
    unit = metadata$unit %||% NA_character_,
    data_type = metadata$data_type %||% NA_character_,
    format = metadata$format %||% NA_character_,
    n_rows = metadata$n_rows %||% NA_character_,
    n_cols = metadata$n_cols %||% NA_character_,
    update_frequency = metadata$update_frequency %||% NA_character_,
    level = metadata$level %||% NA_character_,
    concepts = concepts,
    zero_waste_score = metadata_zero_waste_score(metadata),
    fiche = file.path(dataset_dir, "fiche.qmd"),
    status = metadata$status %||% NA_character_,
    stringsAsFactors = FALSE
  )
}

build_catalogue <- function(datasets_dir = "datasets") {
  if (!dir.exists(datasets_dir)) {
    stop("Le dossier des jeux de données est introuvable : ", datasets_dir, call. = FALSE)
  }

  dataset_dirs <- list.dirs(datasets_dir, full.names = TRUE, recursive = FALSE)
  dataset_dirs <- dataset_dirs[file.exists(file.path(dataset_dirs, "metadata.yml"))]

  if (length(dataset_dirs) == 0L) {
    stop("Aucun fichier metadata.yml trouvé.", call. = FALSE)
  }

  rows <- lapply(dataset_dirs, function(dataset_dir) {
    metadata <- read_dataset_metadata(dataset_dir)
    metadata_row(metadata, dataset_dir)
  })

  do.call(rbind, rows)
}

write_catalogue <- function(catalogue, path = "data/metadata/catalogue.csv") {
  if (!requireNamespace("readr", quietly = TRUE)) {
    stop("Le package readr est requis.", call. = FALSE)
  }

  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  readr::write_csv(catalogue, path)
  invisible(path)
}

