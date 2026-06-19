ulaval_source_candidates <- function(root = ".") {
  env_path <- Sys.getenv("DONNEES_ULAVAL_SOURCE", unset = "")
  candidates <- c(
    env_path,
    file.path(root, ".private", "donnees-ulaval-institutionnelles"),
    file.path(root, "data", "private", "donnees-ulaval-institutionnelles"),
    file.path(dirname(normalizePath(root, mustWork = FALSE)), "donnees-ulaval-institutionnelles")
  )
  candidates[nzchar(candidates)]
}

find_ulaval_source <- function(root = ".", source_path = NULL, require_source = FALSE) {
  candidates <- if (!is.null(source_path) && nzchar(source_path)) {
    source_path
  } else {
    ulaval_source_candidates(root)
  }

  for (candidate in candidates) {
    if (dir.exists(candidate) && file.exists(file.path(candidate, "datapackage.json"))) {
      return(normalizePath(candidate, mustWork = TRUE))
    }
  }

  if (require_source) {
    stop(
      "Source ULaval introuvable. Définir DONNEES_ULAVAL_SOURCE ou cloner le dépôt privé dans .private/donnees-ulaval-institutionnelles.",
      call. = FALSE
    )
  }

  NA_character_
}

ulaval_required_reference_files <- function() {
  c(
    "README.md",
    "NOTICE_DROITS_ET_REUTILISATION.md",
    "datapackage.json",
    "data/catalogue_jeux_de_donnees.csv",
    "data/sources.csv",
    "docs/PROVENANCE_ET_QUALITE.md",
    "docs/GUIDE_D_IMPORTATION.md",
    "metadata/dictionnaire_champs.csv"
  )
}

ulaval_dataset_manifest <- function() {
  data.frame(
    dataset_id = c(
      "programmes_actifs",
      "cours_accessibles",
      "cours_nouveaux",
      "ges_portees_1_2_historique",
      "ges_bilan_2023_2024",
      "ges_portee_3",
      "indicateurs_reperes"
    ),
    phase = c(
      "core",
      "core",
      "core",
      "ges",
      "ges",
      "ges",
      "indicateurs"
    ),
    file = c(
      "data/ulaval_programmes_actifs_2026_06.csv",
      "data/ulaval_cours_accessibles_2026_01_29.csv",
      "data/ulaval_cours_nouveaux_2024_2025.csv",
      "data/ulaval_ges_portees_1_2_historique.csv",
      "data/ulaval_ges_bilan_2023_2024.csv",
      "data/ulaval_ges_portee_3_historique.csv",
      "data/ulaval_indicateurs_reperes_2025.csv"
    ),
    expected_rows = c(753L, 344L, 278L, 15L, 7L, 97L, 165L),
    key_fields = c(
      "code_programme",
      "code_cours",
      "code_cours",
      "periode",
      "periode,element",
      "categorie_code,periode,metrique",
      "indicateur_id,periode,sous_groupe"
    ),
    protected_fields = c(
      "source_id,page_source",
      "source_id,page_source",
      "source_id,page_source",
      "source_id,page_source,note",
      "source_id,page_source,note",
      "source_id,page_source,note,statut_quantification",
      "source_id,page_source,note,statut_valeur"
    ),
    stringsAsFactors = FALSE
  )
}

normalize_ulaval_phases <- function(phases = "core") {
  phases <- unlist(strsplit(paste(phases, collapse = ","), ",", fixed = TRUE))
  phases <- trimws(phases)
  phases <- phases[nzchar(phases)]

  if (length(phases) == 0L) {
    phases <- "core"
  }

  if ("all" %in% phases) {
    phases <- c("core", "ges", "indicateurs")
  }

  unique(phases)
}

ulaval_manifest_for_phases <- function(phases = c("core", "ges")) {
  phases <- normalize_ulaval_phases(phases)
  manifest <- ulaval_dataset_manifest()
  manifest[manifest$phase %in% phases, , drop = FALSE]
}

read_ulaval_csv <- function(path) {
  read.csv(
    path,
    fileEncoding = "UTF-8",
    stringsAsFactors = FALSE,
    check.names = FALSE,
    colClasses = "character",
    na.strings = character(0)
  )
}

stop_if_any <- function(errors, message = "Validation ULaval échouée.") {
  if (length(errors) > 0L) {
    cat(paste(errors, collapse = "\n"), "\n")
    stop(message, call. = FALSE)
  }
}

validate_ulaval_no_platform_pdfs <- function(root = ".") {
  pdf_files <- list.files(
    root,
    pattern = "[.]pdf$",
    recursive = TRUE,
    full.names = TRUE,
    all.files = TRUE,
    no.. = TRUE,
    ignore.case = TRUE
  )

  if (length(pdf_files) == 0L) {
    return(invisible(TRUE))
  }

  normalized <- gsub("\\\\", "/", pdf_files)
  ignored <- grepl("(^|/)\\.git/", normalized) |
    grepl("(^|/)\\.private/", normalized) |
    grepl("(^|/)data/private/", normalized) |
    grepl("(^|/)data/raw/", normalized) |
    grepl("(^|/)data/processed/", normalized)

  unexpected <- pdf_files[!ignored]

  if (length(unexpected) > 0L) {
    stop(
      "PDF source détecté dans le dépôt de plateforme : ",
      paste(unexpected, collapse = ", "),
      call. = FALSE
    )
  }

  invisible(TRUE)
}

validate_ulaval_rights_mentions <- function(root = ".", source_path) {
  required_source_texts <- c(
    "compilation indépendante et non officielle",
    "Il n’est ni publié, ni approuvé, ni maintenu par l’Université Laval",
    "aucune licence ouverte explicite"
  )

  source_files <- c(
    file.path(source_path, "README.md"),
    file.path(source_path, "NOTICE_DROITS_ET_REUTILISATION.md")
  )
  source_text <- paste(unlist(lapply(source_files, readLines, warn = FALSE, encoding = "UTF-8")), collapse = "\n")
  source_text_for_matching <- tolower(source_text)

  missing_source <- required_source_texts[
    !vapply(tolower(required_source_texts), grepl, logical(1), x = source_text_for_matching, fixed = TRUE)
  ]

  platform_files <- c(
    file.path(root, "donnees-ulaval.qmd"),
    file.path(root, "datasets", "ulaval-programmes-cours", "metadata.yml"),
    file.path(root, "datasets", "ulaval-programmes-cours", "fiche.qmd")
  )
  platform_files <- platform_files[file.exists(platform_files)]
  platform_text <- paste(unlist(lapply(platform_files, readLines, warn = FALSE, encoding = "UTF-8")), collapse = "\n")
  platform_text_for_matching <- tolower(platform_text)

  required_platform_texts <- c(
    "compilation indépendante et non officielle",
    "n’est pas un produit officiel ou approuvé par l’Université Laval",
    "aucune licence ouverte explicite"
  )
  missing_platform <- required_platform_texts[
    !vapply(tolower(required_platform_texts), grepl, logical(1), x = platform_text_for_matching, fixed = TRUE)
  ]

  errors <- character()
  if (length(missing_source) > 0L) {
    errors <- c(errors, paste("Mentions de droits absentes dans la source :", paste(missing_source, collapse = ", ")))
  }
  if (length(missing_platform) > 0L) {
    errors <- c(errors, paste("Mentions de droits absentes dans la plateforme :", paste(missing_platform, collapse = ", ")))
  }

  stop_if_any(errors)
  invisible(TRUE)
}

validate_ulaval_dataset_file <- function(source_path, manifest_row, source_ids) {
  file_path <- file.path(source_path, manifest_row$file)
  errors <- character()

  if (!file.exists(file_path)) {
    return(paste("Fichier attendu introuvable :", manifest_row$file))
  }

  data <- read_ulaval_csv(file_path)

  if (nrow(data) != manifest_row$expected_rows) {
    errors <- c(
      errors,
      paste0(
        manifest_row$file,
        " : nombre de lignes attendu ",
        manifest_row$expected_rows,
        ", obtenu ",
        nrow(data)
      )
    )
  }

  key_fields <- trimws(strsplit(manifest_row$key_fields, ",", fixed = TRUE)[[1]])
  missing_key_fields <- setdiff(key_fields, names(data))
  if (length(missing_key_fields) > 0L) {
    errors <- c(errors, paste(manifest_row$file, "clés absentes :", paste(missing_key_fields, collapse = ", ")))
  } else {
    key_values <- do.call(paste, c(data[key_fields], sep = "\r"))
    if (any(duplicated(key_values))) {
      errors <- c(errors, paste(manifest_row$file, "clés non uniques :", paste(key_fields, collapse = ", ")))
    }
  }

  protected_fields <- trimws(strsplit(manifest_row$protected_fields, ",", fixed = TRUE)[[1]])
  missing_protected_fields <- setdiff(protected_fields, names(data))
  if (length(missing_protected_fields) > 0L) {
    errors <- c(
      errors,
      paste(manifest_row$file, "champs de provenance absents :", paste(missing_protected_fields, collapse = ", "))
    )
  }

  if ("source_id" %in% names(data)) {
    unknown_sources <- setdiff(unique(data$source_id), source_ids)
    unknown_sources <- unknown_sources[nzchar(unknown_sources)]
    if (length(unknown_sources) > 0L) {
      errors <- c(errors, paste(manifest_row$file, "source_id inconnus :", paste(unknown_sources, collapse = ", ")))
    }
  }

  if (identical(manifest_row$dataset_id, "cours_nouveaux") && "ordre_source" %in% names(data)) {
    ordre <- suppressWarnings(as.integer(data$ordre_source))
    if (!identical(ordre, seq_len(nrow(data)))) {
      errors <- c(errors, paste(manifest_row$file, "ordre_source n'est pas la séquence attendue."))
    }
  }

  if (identical(manifest_row$dataset_id, "ges_portee_3")) {
    if (!"valeur" %in% names(data) || !"statut_quantification" %in% names(data)) {
      errors <- c(errors, paste(manifest_row$file, "colonnes valeur ou statut_quantification absentes."))
    } else {
      missing_values <- data$valeur == ""
      if (!any(missing_values)) {
        errors <- c(errors, paste(manifest_row$file, "aucune valeur manquante de portée 3 détectée."))
      }
      forbidden_zero <- data$statut_quantification != "quantifiee" & data$valeur == "0"
      if (any(forbidden_zero)) {
        errors <- c(errors, paste(manifest_row$file, "valeurs manquantes ou non quantifiées converties en zéros."))
      }
    }
  }

  errors
}

validate_ulaval_private_source <- function(root = ".", source_path = NULL, phases = c("core", "ges"), require_source = TRUE) {
  source_path <- find_ulaval_source(root, source_path, require_source = require_source)
  if (is.na(source_path)) {
    message("Validation ULaval ignorée : dépôt source privé introuvable.")
    return(invisible(data.frame(control = "source_absente", status = "skipped")))
  }

  errors <- character()

  required_files <- ulaval_required_reference_files()
  missing_reference_files <- required_files[!file.exists(file.path(source_path, required_files))]
  if (length(missing_reference_files) > 0L) {
    errors <- c(errors, paste("Fichiers de référence ULaval absents :", paste(missing_reference_files, collapse = ", ")))
  }

  sources_path <- file.path(source_path, "data", "sources.csv")
  if (!file.exists(sources_path)) {
    errors <- c(errors, "data/sources.csv introuvable dans la source ULaval.")
    source_ids <- character()
  } else {
    sources <- read_ulaval_csv(sources_path)
    if (nrow(sources) != 6L) {
      errors <- c(errors, paste("data/sources.csv : 6 lignes attendues, obtenu", nrow(sources)))
    }
    required_source_fields <- c("source_id", "titre", "organisme", "url", "date_consultation", "sha256_fichier_source")
    missing_source_fields <- setdiff(required_source_fields, names(sources))
    if (length(missing_source_fields) > 0L) {
      errors <- c(errors, paste("data/sources.csv champs absents :", paste(missing_source_fields, collapse = ", ")))
    }
    source_ids <- if ("source_id" %in% names(sources)) unique(sources$source_id) else character()
  }

  manifest <- ulaval_manifest_for_phases(phases)
  for (i in seq_len(nrow(manifest))) {
    errors <- c(errors, validate_ulaval_dataset_file(source_path, manifest[i, , drop = FALSE], source_ids))
  }

  tryCatch(
    validate_ulaval_no_platform_pdfs(root),
    error = function(e) {
      errors <<- c(errors, conditionMessage(e))
    }
  )

  tryCatch(
    validate_ulaval_rights_mentions(root, source_path),
    error = function(e) {
      errors <<- c(errors, conditionMessage(e))
    }
  )

  stop_if_any(errors)

  data.frame(
    control = c(
      "source_privee",
      "fichiers_reference",
      paste0("fichier_", manifest$dataset_id),
      "absence_pdf_plateforme",
      "mentions_droits"
    ),
    status = "ok",
    stringsAsFactors = FALSE
  )
}

copy_ulaval_file <- function(relative_file, source_path, output_dir) {
  source_file <- file.path(source_path, relative_file)
  target_file <- file.path(output_dir, relative_file)
  dir.create(dirname(target_file), recursive = TRUE, showWarnings = FALSE)

  if (!file.copy(source_file, target_file, overwrite = TRUE, copy.date = TRUE)) {
    stop("Copie impossible : ", relative_file, call. = FALSE)
  }

  target_file
}

import_ulaval_datasets <- function(root = ".", source_path = NULL, output_dir = file.path(root, "data", "processed", "ulaval"), phases = "core") {
  source_path <- find_ulaval_source(root, source_path, require_source = TRUE)
  phases <- normalize_ulaval_phases(phases)

  validation_phases <- phases[phases %in% c("core", "ges", "indicateurs")]
  validate_ulaval_private_source(root = root, source_path = source_path, phases = validation_phases, require_source = TRUE)

  manifest <- ulaval_manifest_for_phases(phases)
  data_files <- manifest$file

  metadata_files <- c(
    "README.md",
    "NOTICE_DROITS_ET_REUTILISATION.md",
    "datapackage.json",
    "data/catalogue_jeux_de_donnees.csv",
    "data/sources.csv",
    "metadata/dictionnaire_champs.csv",
    "docs/PROVENANCE_ET_QUALITE.md",
    "docs/GUIDE_D_IMPORTATION.md"
  )

  copied <- vapply(
    c(data_files, metadata_files),
    copy_ulaval_file,
    character(1),
    source_path = source_path,
    output_dir = output_dir
  )

  pdf_files <- list.files(output_dir, pattern = "[.]pdf$", recursive = TRUE, full.names = TRUE, ignore.case = TRUE)
  if (length(pdf_files) > 0L) {
    stop("Des PDF ont été copiés alors que cette opération est interdite : ", paste(pdf_files, collapse = ", "), call. = FALSE)
  }

  copied
}
