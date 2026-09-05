source(if (file.exists("R/utils_taxonomy.R")) "R/utils_taxonomy.R" else "../../R/utils_taxonomy.R")
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
    "script_file",
    "classroom_archive",
    "access_mode",
    "duration",
    "level",
    "activity_type",
    "concepts",
    "context",
    "hook",
    "materials",
    "advanced_math_stats",
    "teacher_notes",
    "pedagogical_status",
    "teacher_preparation",
    "expected_output",
    "learning_objectives",
    "prerequisites",
    "success_criteria",
    "adaptations",
    "requires_prepared_data",
    "requires_live_download",
    "recommended_use",
    "result_visible_in_page",
    "status"
  )
}

required_activity_contract_fields <- function() {
  c(
    "learning_objectives",
    "prerequisites",
    "teacher_preparation",
    "expected_output",
    "success_criteria",
    "adaptations"
  )
}

required_activity_sections <- function() {
  list(
    contexte = "^##\\s+Contexte\\b",
    preparation = "^##\\s+Préparation enseignante\\b",
    consignes = "^##\\s+Consignes\\b",
    resultat = "^##\\s+(Résultat attendu|Résultats attendus|Attendu)\\b",
    limites = "^##\\s+Limites à faire nommer\\b"
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
  validate_taxonomy_metadata(metadata)
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
    script_file = metadata$script_file,
    classroom_archive = metadata$classroom_archive,
    access_mode = metadata$access_mode,
    duration = metadata$duration,
    level = metadata$level,
    activity_type = collapse_activity_field(metadata$activity_type),
    concepts = collapse_activity_field(metadata$concepts),
    concept_ids = collapse_activity_field(metadata$concept_ids),
    level_ids = collapse_activity_field(metadata$level_ids),
    search_aliases = taxonomy_search_aliases(metadata$concept_ids),
    context = metadata$context,
    hook = metadata$hook,
    materials = collapse_activity_field(metadata$materials),
    advanced_math_stats = as.logical(metadata$advanced_math_stats),
    teacher_notes = metadata$teacher_notes,
    pedagogical_status = metadata$pedagogical_status,
    teacher_preparation = metadata$teacher_preparation,
    expected_output = metadata$expected_output,
    learning_objectives = collapse_activity_field(metadata$learning_objectives),
    prerequisites = collapse_activity_field(metadata$prerequisites),
    success_criteria = collapse_activity_field(metadata$success_criteria),
    adaptations = collapse_activity_field(metadata$adaptations),
    requires_prepared_data = as.logical(metadata$requires_prepared_data),
    requires_live_download = as.logical(metadata$requires_live_download),
    recommended_use = metadata$recommended_use,
    result_visible_in_page = as.logical(metadata$result_visible_in_page),
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

  text_fields <- c(
    "pedagogical_status",
    "teacher_preparation",
    "expected_output",
    "recommended_use"
  )
  for (field in text_fields) {
    if (any(is.na(catalogue[[field]]) | catalogue[[field]] == "")) {
      stop("Le champ d'activité ", field, " doit être non vide.", call. = FALSE)
    }
  }

  contract_fields <- required_activity_contract_fields()
  for (field in contract_fields) {
    values <- trimws(as.character(catalogue[[field]]))
    if (any(is.na(values) | values == "")) {
      stop("Le champ du contrat pédagogique ", field, " doit être non vide.", call. = FALSE)
    }
  }

  allowed_status <- c("pret_a_enseigner", "a_consolider", "ebauche")
  invalid_status <- setdiff(unique(catalogue$pedagogical_status), allowed_status)
  if (length(invalid_status) > 0L) {
    stop(
      "Statuts pédagogiques invalides : ",
      paste(invalid_status, collapse = ", "),
      call. = FALSE
    )
  }

  logical_fields <- c(
    "advanced_math_stats",
    "requires_prepared_data",
    "requires_live_download",
    "result_visible_in_page"
  )
  for (field in logical_fields) {
    if (any(is.na(catalogue[[field]]))) {
      stop("Le champ logique ", field, " doit être TRUE ou FALSE.", call. = FALSE)
    }
  }

  invisible(catalogue)
}

validate_activity_pages <- function(catalogue) {
  required_sections <- required_activity_sections()
  errors <- character()

  for (i in seq_len(nrow(catalogue))) {
    activity_path <- catalogue$activity_url[[i]]
    if (!file.exists(activity_path)) {
      errors <- c(errors, paste("Page d'activité introuvable :", activity_path))
      next
    }

    content <- paste(readLines(activity_path, warn = FALSE), collapse = "\n")
    section_present <- vapply(required_sections, function(pattern) {
      grepl(paste0("(?m)", pattern), content, perl = TRUE)
    }, logical(1))
    missing_sections <- names(required_sections)[!section_present]

    if (length(missing_sections) > 0L) {
      errors <- c(
        errors,
        paste(
          activity_path,
          "sections manquantes :",
          paste(missing_sections, collapse = ", ")
        )
      )
    }

    materials <- collapse_activity_field(strsplit(catalogue$materials[[i]], ";\\s*")[[1]])
    mentions_code <- grepl("code", materials, ignore.case = TRUE)
    has_r_chunk <- grepl("```\\{r", content, fixed = FALSE)
    explains_no_code <- grepl("Je ne sais pas.|aucun CSV préparé|source à auditer", content)
    if (mentions_code && !has_r_chunk && !explains_no_code) {
      errors <- c(errors, paste(activity_path, "annonce du code sans bloc R ni justification."))
    }

    data_paths <- regmatches(
      content,
      gregexpr("data/processed/[^\"` )\n]+[.]csv", content, perl = TRUE)
    )[[1]]
    data_paths <- unique(data_paths)
    if (length(data_paths) > 0L) {
      missing_data <- data_paths[!file.exists(data_paths)]
      has_preparation_note <- grepl("Préparation requise|preparation[.]R|préparation requise", content)
      if (length(missing_data) > 0L && !has_preparation_note) {
        errors <- c(
          errors,
          paste(activity_path, "référence des CSV absents sans préparation explicite :", paste(missing_data, collapse = ", "))
        )
      }
    }
  }

  if (length(errors) > 0L) {
    stop(paste(errors, collapse = "\n"), call. = FALSE)
  }

  invisible(catalogue)
}

validate_activity_contract_renderers <- function(catalogue, root = ".") {
  paths <- file.path(root, catalogue$activity_url)
  missing_renderer <- vapply(paths, function(path) {
    !file.exists(path) || !any(grepl(
      "render_activity_contract\\(\\)",
      readLines(path, warn = FALSE, encoding = "UTF-8")
    ))
  }, logical(1))

  if (any(missing_renderer)) {
    stop(
      "Chaque activité doit rendre son contrat pédagogique. Pages incomplètes : ",
      paste(catalogue$activity_url[missing_renderer], collapse = ", "),
      call. = FALSE
    )
  }

  invisible(TRUE)
}

validate_activity_resources <- function(catalogue) {
  source('R/utils_classroom.R')
  for (i in seq_len(nrow(catalogue))) {
    item <- catalogue[i, ]
    if (!file.exists(item$script_file) || !file.exists(item$classroom_archive)) {
      stop('Ressource de lancement absente : ', item$id, call. = FALSE)
    }
    if (!item$access_mode %in% c('frozen', 'documentation', 'source_required') ||
        item$requires_live_download != (item$access_mode == 'source_required')) {
      stop('Mode d’accès incohérent : ', item$id, call. = FALSE)
    }
    if (item$pedagogical_status == 'pret_a_enseigner' && item$access_mode == 'source_required') {
      stop('Acquisition préalable masquée par le statut : ', item$id, call. = FALSE)
    }
    parse(item$script_file)
    metadata <- yaml::read_yaml(file.path('datasets', item$dataset_id, 'metadata.yml'))
    if (classroom_policy(metadata)$mode != item$access_mode) stop('Politiques divergentes : ', item$id)
  }
  invisible(TRUE)
}
