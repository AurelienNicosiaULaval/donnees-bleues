library(dplyr)
library(readr)

input_path <- "data/processed/qualite-air-horaire/resume_journalier_contaminants_2025.csv"
output_path <- "assets/previews/qualite-air-horaire-pm25-radisson-2025.csv"

if (!file.exists(input_path)) {
  stop("Le résumé journalier préparé est requis : ", input_path, call. = FALSE)
}

preview <- read_csv(input_path, show_col_types = FALSE) |>
  filter(
    .data$station_name == "Radisson",
    .data$contaminant_source == "PM2.5-T640",
    .data$n_heures_valides >= 18
  ) |>
  arrange(.data$date) |>
  slice(round(seq(1, n(), length.out = min(120L, n())))) |>
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

if (nrow(preview) < 2L) {
  stop("L'extrait public doit contenir au moins deux résumés journaliers.", call. = FALSE)
}

dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
write_csv(preview, output_path)

message("Extrait public créé : ", output_path, " (", nrow(preview), " lignes)")
