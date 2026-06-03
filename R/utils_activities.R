`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0L || all(is.na(x))) y else x
}

required_activity_fields <- function() {
  c(
    "id",
    "title",
    "question",
    "dataset_id",
    "dataset_title",
    "activity_url",
    "duration",
    "level",
    "activity_type",
    "concepts",
    "context",
    "hook",
    "materials",
    "advanced_math_stats",
    "teacher_notes",
    "status"
  )
}

read_activity_metadata <- function(path) {
  if (!requireNamespace("yaml", quietly = TRUE)) {
    stop("Le package yaml est requis.", call. = FALSE)
  }

  if (!file.exists(path)) {
    stop("Fichier de métadonnées d'activité introuvable : ", path, call. = FALSE)
  }

  yaml::read_yaml(path)
}

collapse_activity_field <- function(x) {
  paste(unlist(x %||% character()), collapse = "; ")
}

activity_metadata_row <- function(metadata, metadata_path) {
  missing_fields <- setdiff(required_activity_fields(), names(metadata))
  if (length(missing_fields) > 0L) {
    stop(
      "Champs manquants dans ",
      metadata_path,
      " : ",
      paste(missing_fields, collapse = ", "),
      call. = FALSE
    )
  }

  data.frame(
    id = metadata$id,
    title = metadata$title,
    question = metadata$question,
    dataset_id = metadata$dataset_id,
    dataset_title = metadata$dataset_title,
    activity_url = metadata$activity_url,
    duration = metadata$duration,
    level = metadata$level,
    activity_type = collapse_activity_field(metadata$activity_type),
    concepts = collapse_activity_field(metadata$concepts),
    context = metadata$context,
    hook = metadata$hook,
    materials = collapse_activity_field(metadata$materials),
    advanced_math_stats = as.logical(metadata$advanced_math_stats),
    teacher_notes = metadata$teacher_notes,
    status = metadata$status,
    stringsAsFactors = FALSE
  )
}

build_activity_catalogue <- function(datasets_dir = "datasets") {
  if (!dir.exists(datasets_dir)) {
    stop("Le dossier des jeux de données est introuvable : ", datasets_dir, call. = FALSE)
  }

  metadata_paths <- list.files(
    datasets_dir,
    pattern = "^activite-.*[.]yml$",
    recursive = TRUE,
    full.names = TRUE
  )

  if (length(metadata_paths) == 0L) {
    stop("Aucune métadonnée d'activité trouvée.", call. = FALSE)
  }

  rows <- lapply(metadata_paths, function(metadata_path) {
    metadata <- read_activity_metadata(metadata_path)
    activity_metadata_row(metadata, metadata_path)
  })

  catalogue <- do.call(rbind, rows)
  catalogue[order(catalogue$dataset_id, catalogue$duration, catalogue$title), , drop = FALSE]
}

write_activity_catalogue <- function(catalogue, path = "data/metadata/catalogue_activites.csv") {
  if (!requireNamespace("readr", quietly = TRUE)) {
    stop("Le package readr est requis.", call. = FALSE)
  }

  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  readr::write_csv(catalogue, path)
  invisible(path)
}

validate_activity_catalogue <- function(catalogue) {
  if (!is.data.frame(catalogue)) {
    stop("Le catalogue d'activités doit être un data frame.", call. = FALSE)
  }

  missing_columns <- setdiff(required_activity_fields(), names(catalogue))
  if (length(missing_columns) > 0L) {
    stop(
      "Colonnes manquantes dans le catalogue d'activités : ",
      paste(missing_columns, collapse = ", "),
      call. = FALSE
    )
  }

  if (any(is.na(catalogue$id) | catalogue$id == "")) {
    stop("Chaque activité doit avoir un identifiant non vide.", call. = FALSE)
  }

  if (any(duplicated(catalogue$id))) {
    stop("Les identifiants d'activités doivent être uniques.", call. = FALSE)
  }

  if (any(is.na(catalogue$activity_url) | catalogue$activity_url == "")) {
    stop("Chaque activité doit avoir une URL relative.", call. = FALSE)
  }

  invisible(catalogue)
}

