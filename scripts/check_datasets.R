source("R/utils_catalogue.R")
source("R/utils_zero_waste.R")
source("R/utils_activities.R")
source("R/utils_ulaval.R")
source("R/utils_card_images.R")
source("R/utils_site_validation.R")

required_files <- c(
  "fiche.qmd",
  "activite-courte.qmd",
  "activite-courte.yml",
  "activite-longue.qmd",
  "activite-longue.yml",
  "preparation.R",
  "metadata.yml"
)
required_fields <- c(
  "id", "title", "short_title", "theme", "source_name", "source_url",
  "license", "access_date", "geography", "unit", "data_type", "format",
  "n_rows", "n_cols", "update_frequency", "level", "concepts",
  "zero_waste", "status"
)

dataset_dirs <- find_dataset_dirs("datasets")

if (length(dataset_dirs) == 0L) {
  stop("Aucun dossier de jeu de données trouvé dans datasets/.", call. = FALSE)
}

errors <- character()

for (dataset_dir in dataset_dirs) {
  missing_files <- required_files[!file.exists(file.path(dataset_dir, required_files))]
  if (length(missing_files) > 0L) {
    errors <- c(errors, paste(dataset_dir, "fichiers manquants :", paste(missing_files, collapse = ", ")))
    next
  }

  metadata <- read_dataset_metadata(dataset_dir)
  missing_fields <- required_fields[!required_fields %in% names(metadata)]
  if (length(missing_fields) > 0L) {
    errors <- c(errors, paste(dataset_dir, "champs metadata manquants :", paste(missing_fields, collapse = ", ")))
  }

  tryCatch(
    validate_zero_waste_score(metadata$zero_waste),
    error = function(e) {
      errors <<- c(errors, paste(dataset_dir, "score zéro déchet invalide :", conditionMessage(e)))
    }
  )
}

catalogue <- build_catalogue("datasets")
validate_card_images(catalogue)

catalogue_activites <- build_activity_catalogue("datasets")
validate_activity_catalogue(catalogue_activites)
validate_activity_pages(catalogue_activites)
validate_activity_contract_renderers(catalogue_activites)
validate_documented_paths()

tryCatch(
  validate_ulaval_private_source(root = ".", phases = c("core", "ges"), require_source = FALSE),
  error = function(e) {
    errors <<- c(errors, paste("Validation ULaval invalide :", conditionMessage(e)))
  }
)

missing_activity_pages <- catalogue_activites$activity_url[
  !file.exists(catalogue_activites$activity_url)
]

if (length(missing_activity_pages) > 0L) {
  errors <- c(
    errors,
    paste(
      "Pages d'activités introuvables :",
      paste(missing_activity_pages, collapse = ", ")
    )
  )
}

if (length(errors) > 0L) {
  cat(paste(errors, collapse = "\n"), "\n")
  stop("La vérification des jeux de données a échoué.", call. = FALSE)
}

message("Tous les jeux de données et activités déclarés sont cohérents.")
