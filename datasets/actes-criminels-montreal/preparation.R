# Préparation : actes criminels à Montréal
# Source officielle : Données Québec / Ville de Montréal, paquet CKAN 5829b5b0-ea6f-476f-be94-bc2b8797769a.

library(dplyr)
library(jsonlite)
library(readr)
library(tidyr)

find_project_root <- function(path = getwd()) {
  current <- normalizePath(path, mustWork = FALSE)
  repeat {
    if (file.exists(file.path(current, "_quarto.yml"))) {
      return(current)
    }
    parent <- dirname(current)
    if (identical(parent, current)) {
      stop("Impossible de trouver la racine du projet contenant _quarto.yml.", call. = FALSE)
    }
    current <- parent
  }
}

root <- find_project_root()
raw_dir <- file.path(root, "data/raw/actes-criminels-montreal")
processed_dir <- file.path(root, "data/processed/actes-criminels-montreal")
dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(processed_dir, recursive = TRUE, showWarnings = FALSE)

access_date <- as.Date("2026-06-21")
source_page <- "https://www.donneesquebec.ca/recherche/dataset/vmtl-actes-criminels"
source_api <- "https://www.donneesquebec.ca/recherche/api/3/action/package_show?id=vmtl-actes-criminels"
source_montreal_page <- "https://donnees.montreal.ca/dataset/actes-criminels"
source_bilan_mensuel <- "https://donnees.montreal.ca/dataset/bilan-mensuel-criminalite"
source_visualisation <- "https://ville.montreal.qc.ca/vuesurlasecuritepublique/"
csv_url <- "https://donnees.montreal.ca/dataset/5829b5b0-ea6f-476f-be94-bc2b8797769a/resource/c6f482bf-bf0f-4960-8b2f-9982c211addd/download/actes-criminels.csv"

package_json_path <- file.path(raw_dir, "package_show_actes_criminels.json")
csv_raw_path <- file.path(raw_dir, "actes-criminels.csv")

download.file(source_api, package_json_path, mode = "wb", quiet = TRUE)
download.file(csv_url, csv_raw_path, mode = "wb", quiet = TRUE)

package <- fromJSON(package_json_path)
if (!isTRUE(package$success)) {
  stop("L'API CKAN n'a pas retourné success = TRUE.", call. = FALSE)
}

resources <- package$result$resources |>
  transmute(
    resource_id = id,
    resource_name = name,
    format = toupper(format),
    url = url,
    description = description,
    last_modified = as.character(last_modified),
    size = suppressWarnings(as.numeric(size))
  )

source_data <- read_csv(
  csv_raw_path,
  locale = locale(encoding = "UTF-8"),
  show_col_types = FALSE
)

expected_columns <- c("CATEGORIE", "DATE", "QUART", "PDQ", "X", "Y", "LONGITUDE", "LATITUDE")
if (!identical(names(source_data), expected_columns)) {
  stop(
    "Structure source inattendue. Champs observés : ",
    paste(names(source_data), collapse = ", "),
    call. = FALSE
  )
}

actes <- source_data |>
  transmute(
    categorie = CATEGORIE,
    date = as.Date(DATE),
    annee = as.integer(format(date, "%Y")),
    mois = format(date, "%Y-%m"),
    quart = QUART,
    pdq = as.integer(PDQ),
    x_mtm8 = as.numeric(X),
    y_mtm8 = as.numeric(Y),
    longitude = as.numeric(LONGITUDE),
    latitude = as.numeric(LATITUDE),
    localisation_disponible = !is.na(longitude) & !is.na(latitude),
    source_csv_url = csv_url,
    access_date = access_date
  ) |>
  arrange(date, categorie, pdq)

summary_by_category <- actes |>
  count(categorie, name = "n_actes") |>
  mutate(pct_actes = round(100 * n_actes / sum(n_actes), 1)) |>
  arrange(desc(n_actes))

summary_by_quart <- actes |>
  count(quart, name = "n_actes") |>
  mutate(pct_actes = round(100 * n_actes / sum(n_actes), 1)) |>
  arrange(desc(n_actes))

summary_by_year <- actes |>
  count(annee, name = "n_actes") |>
  mutate(
    periode_complete = annee < max(annee),
    note = if_else(periode_complete, "année complète dans le fichier", "année partielle dans le fichier")
  ) |>
  arrange(annee)

summary_by_month_category <- actes |>
  count(mois, categorie, name = "n_actes") |>
  arrange(mois, categorie)

missing_summary <- actes |>
  summarise(across(everything(), ~ sum(is.na(.x)))) |>
  pivot_longer(
    cols = everything(),
    names_to = "variable",
    values_to = "n_missing"
  ) |>
  mutate(
    n_rows = nrow(actes),
    pct_missing = round(100 * n_missing / n_rows, 2)
  ) |>
  arrange(desc(n_missing), variable)

dataset_summary <- tibble::tibble(
  metric = c(
    "source_page",
    "source_api",
    "source_montreal_page",
    "source_bilan_mensuel",
    "source_visualisation",
    "csv_url",
    "access_date",
    "package_id",
    "metadata_modified",
    "csv_resource_last_modified",
    "csv_resource_size",
    "license_title",
    "n_resources_ckan",
    "n_rows_source",
    "n_columns_source",
    "n_rows_prepared",
    "n_columns_prepared",
    "first_date",
    "last_date",
    "n_categories",
    "n_quarts",
    "n_pdq_non_missing",
    "n_missing_pdq",
    "n_missing_coordinates",
    "pct_missing_coordinates"
  ),
  value = c(
    source_page,
    source_api,
    source_montreal_page,
    source_bilan_mensuel,
    source_visualisation,
    csv_url,
    as.character(access_date),
    package$result$id,
    as.character(package$result$metadata_modified),
    resources$last_modified[resources$url == csv_url],
    as.character(resources$size[resources$url == csv_url]),
    as.character(package$result$license_title),
    as.character(nrow(resources)),
    as.character(nrow(source_data)),
    as.character(ncol(source_data)),
    as.character(nrow(actes)),
    as.character(ncol(actes)),
    as.character(min(actes$date, na.rm = TRUE)),
    as.character(max(actes$date, na.rm = TRUE)),
    as.character(n_distinct(actes$categorie)),
    as.character(n_distinct(actes$quart)),
    as.character(n_distinct(actes$pdq, na.rm = TRUE)),
    as.character(sum(is.na(actes$pdq))),
    as.character(sum(!actes$localisation_disponible)),
    as.character(round(100 * sum(!actes$localisation_disponible) / nrow(actes), 1))
  )
)

stopifnot(
  nrow(resources) == 3,
  nrow(actes) > 300000,
  ncol(source_data) == 8,
  n_distinct(actes$categorie) == 6,
  n_distinct(actes$quart) == 3,
  n_distinct(actes$pdq, na.rm = TRUE) >= 30,
  min(actes$date, na.rm = TRUE) == as.Date("2015-01-01"),
  max(actes$date, na.rm = TRUE) >= as.Date("2026-01-01")
)

write_csv(resources, file.path(processed_dir, "ressources_ckan_actes_criminels.csv"))
write_csv(actes, file.path(processed_dir, "actes_criminels_montreal.csv"))
write_csv(summary_by_category, file.path(processed_dir, "resume_categories_actes_criminels.csv"))
write_csv(summary_by_quart, file.path(processed_dir, "resume_quarts_actes_criminels.csv"))
write_csv(summary_by_year, file.path(processed_dir, "resume_annees_actes_criminels.csv"))
write_csv(summary_by_month_category, file.path(processed_dir, "resume_mois_categories_actes_criminels.csv"))
write_csv(missing_summary, file.path(processed_dir, "valeurs_manquantes_actes_criminels.csv"))
write_csv(dataset_summary, file.path(processed_dir, "resume_actes_criminels.csv"))
