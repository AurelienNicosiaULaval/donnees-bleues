library(dplyr)
library(readr)
library(yaml)

`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0L || all(is.na(x))) y else x
}

preview_dir <- "assets/previews"
metadata_paths <- list.files("datasets", pattern = "metadata.yml$", recursive = TRUE, full.names = TRUE)
preview_input_overrides <- c(
  "retards-transport-collectif" = "data/processed/retards-transport-collectif/variables_gtfs_realtime_retards_transport.csv"
)

source("R/utils_publication.R")

sample_preview_rows <- function(data, n_max = 120L) {
  if (nrow(data) == 0L) {
    stop("La table préparée ne contient aucune ligne.", call. = FALSE)
  }
  index <- unique(round(seq(1L, nrow(data), length.out = min(n_max, nrow(data)))))
  data[index, , drop = FALSE]
}

quality_air_preview <- function(input_path) {
  read_csv(input_path, show_col_types = FALSE) |>
    filter(
      .data$station_name == "Radisson",
      .data$contaminant_source == "PM2.5-T640",
      .data$n_heures_valides >= 18
    ) |>
    arrange(.data$date) |>
    sample_preview_rows() |>
    transmute(
      date = .data$date,
      station_id = .data$station_id,
      station_name = .data$station_name,
      contaminant = .data$contaminant,
      n_heures_valides = .data$n_heures_valides,
      moyenne = round(.data$moyenne, 3),
      mediane = round(.data$mediane, 3),
      p95 = round(.data$p95, 3),
      maximum = round(.data$maximum, 3),
      source_year = .data$source_year
    )
}

build_preview <- function(metadata_path) {
  metadata <- read_yaml(metadata_path)
  id <- as.character(metadata$id %||% basename(dirname(metadata_path)))
  validate_publication_policy(metadata)
  if (!isTRUE(metadata$publication$preview)) {
    return(tibble(id = id, status = "protégé", output = NA_character_, rows = NA_integer_))
  }

  override_path <- unname(preview_input_overrides[id])
  input_path <- if (length(override_path) == 1L && !is.na(override_path)) {
    override_path
  } else {
    as.character(metadata$processed_file %||% metadata$processed_path %||% "")
  }
  if (input_path == "" || !file.exists(input_path)) {
    stop("Table préparée introuvable pour ", id, " : ", input_path, call. = FALSE)
  }

  output_path <- as.character(metadata$preview_file %||% file.path(preview_dir, paste0(id, ".csv")))
  preview <- if (identical(id, "qualite-air-horaire")) {
    quality_air_preview(input_path)
  } else {
    prepared_data <- read_csv(
      input_path,
      col_types = cols(.default = col_character()),
      show_col_types = FALSE
    )
    prepared_data |>
      select(all_of(unlist(metadata$publication$preview_columns))) |>
      sample_preview_rows()
  }

  dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
  write_csv(preview, output_path)
  validate_public_preview(metadata, output_path)
  prepared_manifest <- jsonlite::read_json(file.path(dirname(input_path), "manifest.json"))
  receipt <- list(dataset_id = id, prepared_at_utc = prepared_manifest$prepared_at_utc,
    prepared_file = basename(input_path), prepared_sha256 = digest::digest(file = input_path, algo = "sha256"),
    preview_sha256 = digest::digest(file = output_path, algo = "sha256"), rows = nrow(preview), columns = names(preview),
    selection = if (id == "qualite-air-horaire") "Radisson; PM2.5-T640; au moins 18 heures valides; au plus 120 positions régulièrement espacées dans l'ordre chronologique" else "Au plus 120 positions régulièrement espacées dans l'ordre de la table préparée; sélection déterministe non aléatoire",
    source_name = metadata$source_name, source_url = metadata$source_url,
    license = metadata$license, license_url = metadata$publication$license_url,
    sources = prepared_manifest$sources)
  jsonlite::write_json(receipt, paste0(output_path, ".json"), auto_unbox = TRUE, pretty = TRUE)
  tibble(id = id, status = "publié", output = output_path, rows = nrow(preview))
}

results <- bind_rows(lapply(metadata_paths, build_preview)) |>
  arrange(.data$status, .data$id)

if (any(results$status == "publié" & results$rows < 2L)) {
  stop("Chaque aperçu public doit contenir au moins deux lignes.", call. = FALSE)
}

print(results, n = nrow(results))
