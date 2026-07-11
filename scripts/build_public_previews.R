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

license_blocks_preview <- function(license) {
  grepl(
    "reproduction.*interdite|aucune licence ouverte|réutilisation publique à valider",
    tolower(as.character(license %||% ""))
  )
}

safe_preview_columns <- function(data) {
  columns <- names(data)[vapply(data, function(column) is.atomic(column) && !is.list(column), logical(1))]
  protected <- grepl(
    "adresse|address|adrs|rue|street|civique|postl|postal|courriel|email|telephone|phone|longitude|latitude|(^lat$)|(^lon$)|coord|geom|mtm|(^x$)|(^y$)|(^x_)|(^y_)|site_web|source.*url|nom_exploitant|raison_sociale|nom_intervenant",
    columns,
    ignore.case = TRUE
  )
  columns <- columns[!protected]
  if (length(columns) == 0L) {
    stop("Aucune colonne sûre à publier dans l'extrait.", call. = FALSE)
  }
  head(columns, 10L)
}

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
  if (license_blocks_preview(metadata$license)) {
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
      select(all_of(safe_preview_columns(prepared_data))) |>
      sample_preview_rows()
  }

  dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
  write_csv(preview, output_path)
  tibble(id = id, status = "publié", output = output_path, rows = nrow(preview))
}

results <- bind_rows(lapply(metadata_paths, build_preview)) |>
  arrange(.data$status, .data$id)

if (any(results$status == "publié" & results$rows < 2L)) {
  stop("Chaque aperçu public doit contenir au moins deux lignes.", call. = FALSE)
}

print(results, n = nrow(results))
