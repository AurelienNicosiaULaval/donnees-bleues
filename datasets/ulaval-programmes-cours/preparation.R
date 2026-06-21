# Préparation publique sûre : programmes et cours institutionnels ULaval.
#
# Les CSV sources demeurent privés et ne doivent pas être redistribués dans
# Données bleues. Ce script produit uniquement des résumés de validation et de
# provenance compatibles avec une fiche publique.

library(dplyr)
library(readr)
library(tibble)

source("R/utils_ulaval.R")

dataset_id <- "ulaval-programmes-cours"
processed_dir <- file.path("data", "processed", dataset_id)
dir.create(processed_dir, recursive = TRUE, showWarnings = FALSE)

write_processed_csv <- function(data, filename) {
  readr::write_csv(data, file.path(processed_dir, filename), na = "")
}

source_path <- find_ulaval_source(root = ".", require_source = FALSE)
source_found <- !is.na(source_path)
phases_validated <- c("core", "ges")
manifest <- ulaval_manifest_for_phases(c("core", "ges", "indicateurs"))
reference_files <- ulaval_required_reference_files()

validation_tbl <- if (source_found) {
  validate_ulaval_private_source(
    root = ".",
    source_path = source_path,
    phases = phases_validated,
    require_source = TRUE
  )
} else {
  tibble(
    control = "source_privee",
    status = "skipped",
    detail = "Source privée introuvable. Définir DONNEES_ULAVAL_SOURCE pour valider les fichiers."
  )
}

observed_file_summary <- lapply(seq_len(nrow(manifest)), function(i) {
  item <- manifest[i, , drop = FALSE]
  file_path <- if (source_found) file.path(source_path, item$file) else NA_character_
  exists <- source_found && file.exists(file_path)
  data <- if (exists) read_ulaval_csv(file_path) else NULL
  key_field_names <- trimws(strsplit(item$key_fields, ",", fixed = TRUE)[[1]])
  protected_field_names <- trimws(strsplit(item$protected_fields, ",", fixed = TRUE)[[1]])

  if (!is.null(data) && all(key_field_names %in% names(data))) {
    key_values <- do.call(paste, c(data[key_field_names], sep = "\r"))
    keys_unique <- !any(duplicated(key_values))
  } else {
    keys_unique <- NA
  }

  tibble(
    dataset_id = item$dataset_id,
    phase = item$phase,
    source_file = item$file,
    expected_rows = item$expected_rows,
    observed_rows = if (is.null(data)) NA_integer_ else nrow(data),
    observed_cols = if (is.null(data)) NA_integer_ else ncol(data),
    key_fields = item$key_fields,
    protected_fields = item$protected_fields,
    file_available = exists,
    row_count_matches = if (is.null(data)) NA else nrow(data) == item$expected_rows,
    keys_unique = keys_unique,
    protected_fields_present = if (is.null(data)) NA else all(protected_field_names %in% names(data))
  )
}) |>
  bind_rows()

sources_summary <- if (source_found && file.exists(file.path(source_path, "data", "sources.csv"))) {
  sources <- read_ulaval_csv(file.path(source_path, "data", "sources.csv"))
  tibble(
    n_sources = nrow(sources),
    source_id_present = "source_id" %in% names(sources),
    url_present = "url" %in% names(sources),
    date_consultation_present = "date_consultation" %in% names(sources),
    sha256_present = "sha256_fichier_source" %in% names(sources)
  )
} else {
  tibble(
    n_sources = NA_integer_,
    source_id_present = NA,
    url_present = NA,
    date_consultation_present = NA,
    sha256_present = NA
  )
}

summary_tbl <- tibble(
  access_date = as.character(Sys.Date()),
  source_found = source_found,
  source_status = if (source_found) "source privée locale validée" else "source privée absente dans cet environnement",
  source_path_recorded = if (source_found) "chemin local privé non publié" else "Je ne sais pas.",
  n_reference_files_expected = length(reference_files),
  n_reference_files_available = if (source_found) sum(file.exists(file.path(source_path, reference_files))) else NA_integer_,
  n_manifest_datasets = nrow(manifest),
  n_core_datasets = sum(manifest$phase == "core"),
  n_core_expected_rows = sum(manifest$expected_rows[manifest$phase == "core"]),
  n_ges_datasets = sum(manifest$phase == "ges"),
  n_ges_expected_rows = sum(manifest$expected_rows[manifest$phase == "ges"]),
  n_indicateurs_datasets = sum(manifest$phase == "indicateurs"),
  n_indicateurs_expected_rows = sum(manifest$expected_rows[manifest$phase == "indicateurs"]),
  validation_phases = paste(phases_validated, collapse = ","),
  validation_status = if (source_found && all(validation_tbl$status == "ok")) "ok" else "skipped",
  public_redistribution_status = "Aucune licence ouverte explicite identifiée; republication publique à valider.",
  official_approval_status = "Compilation indépendante et non officielle; pas un produit officiel ou approuvé par l'Université Laval.",
  platform_pdf_policy = "Aucun PDF source ne doit être copié dans le dépôt de plateforme."
)

rights_tbl <- tibble(
  item = c(
    "statut_institutionnel",
    "licence_ouverte",
    "redistribution_publique",
    "donnees_lignes",
    "pdf_sources",
    "valeurs_numeriques",
    "provenance"
  ),
  statement = c(
    "Compilation indépendante et non officielle.",
    "Aucune licence ouverte explicite identifiée dans le paquet source.",
    "Je ne sais pas. Une validation institutionnelle ou juridique est nécessaire avant republication publique à grande échelle.",
    "Les lignes des CSV privés ne sont pas redistribuées dans Données bleues.",
    "Les PDF sources ne sont pas redistribués dans Données bleues.",
    "Les valeurs numériques doivent être conservées telles quelles.",
    "Les champs source_id et page_source doivent être conservés lorsque présents."
  )
)

write_processed_csv(summary_tbl, "resume_ulaval_programmes_cours.csv")
write_processed_csv(validation_tbl, "resume_controles_ulaval.csv")
write_processed_csv(observed_file_summary, "resume_fichiers_ulaval.csv")
write_processed_csv(sources_summary, "resume_sources_ulaval.csv")
write_processed_csv(rights_tbl, "resume_droits_ulaval.csv")

stopifnot(nrow(summary_tbl) == 1)
stopifnot(nrow(observed_file_summary) == 7)
stopifnot(sum(observed_file_summary$phase == "core") == 3)
stopifnot(sum(observed_file_summary$expected_rows[observed_file_summary$phase == "core"]) == 1375)
stopifnot(!any(list.files(processed_dir, pattern = "[.]pdf$", recursive = TRUE, ignore.case = TRUE)))

message("Résumé ULaval généré dans ", processed_dir)
if (!source_found) {
  message("Source privée absente : résumé public produit sans validation des fichiers locaux.")
}
