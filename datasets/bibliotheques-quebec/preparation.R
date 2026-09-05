source("R/utils_downloads.R")
# Préparation : statistiques 2024 des bibliothèques publiques du Québec
# Source officielle : Données Québec / Bibliothèque et Archives nationales du Québec,
# paquet CKAN 231a38a8-f28e-4bef-82ea-dc98a14c1b6f.

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

parse_number_fr <- function(x) {
  if (is.numeric(x)) {
    return(as.numeric(x))
  }

  x <- gsub("\u00a0", " ", as.character(x), fixed = TRUE)
  parse_number(
    x,
    locale = locale(decimal_mark = ",", grouping_mark = " ")
  )
}

ratio_if_possible <- function(numerator, denominator) {
  if_else(
    !is.na(numerator) & !is.na(denominator) & denominator > 0,
    numerator / denominator,
    NA_real_
  )
}

root <- find_project_root()
raw_dir <- file.path(root, "data/raw/bibliotheques-quebec")
processed_dir <- file.path(root, "data/processed/bibliotheques-quebec")
dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(processed_dir, recursive = TRUE, showWarnings = FALSE)

access_date <- Sys.Date()
source_page <- "https://www.donneesquebec.ca/recherche/dataset/statistiques_des_bibliotheques_publiques_du_quebec"
source_api <- "https://www.donneesquebec.ca/recherche/api/3/action/package_show?id=statistiques_des_bibliotheques_publiques_du_quebec"
csv_url <- "https://www.donneesquebec.ca/recherche/dataset/231a38a8-f28e-4bef-82ea-dc98a14c1b6f/resource/01183d3e-c79c-4d09-915c-f35ffe4dfda8/download/statistiques_bibliotheques_quebec_2024.csv"
dictionary_url <- "https://www.donneesquebec.ca/recherche/dataset/231a38a8-f28e-4bef-82ea-dc98a14c1b6f/resource/25bddc87-e71a-4668-bb37-55b30003dd55/download/dictionnaire-des-donnees.csv"

package_json_path <- file.path(raw_dir, "package_show_bibliotheques.json")
csv_raw_path <- file.path(raw_dir, "statistiques_bibliotheques_quebec_2024.csv")

download_source(source_api, package_json_path, mode = "wb", quiet = TRUE)
download_source(csv_url, csv_raw_path, mode = "wb", quiet = TRUE)

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

source_data <- read_delim(
  csv_raw_path,
  delim = ";",
  locale = locale(encoding = "UTF-8", decimal_mark = ","),
  show_col_types = FALSE
)

required_columns <- c(
  "Bibliothèque ou Centre régional",
  "Région administrative",
  "Population desservie",
  "Catégorie de la bibl.",
  "Modalités d'abonnement",
  "Visites (Total)",
  "Prêts / Tous les doc. (Total)",
  "Usagers inscrits (Total)",
  "Progr. / Toutes les activités (Total)",
  "Dép. fonct. / Toutes les dépenses ($)"
)

missing_columns <- setdiff(required_columns, names(source_data))
if (length(missing_columns) > 0L) {
  stop("Champs source absents : ", paste(missing_columns, collapse = ", "), call. = FALSE)
}

bibliotheques <- source_data |>
  transmute(
    bibliotheque = `Bibliothèque ou Centre régional`,
    region_administrative = `Région administrative`,
    population_desservie = parse_number_fr(`Population desservie`),
    categorie_bibliotheque = `Catégorie de la bibl.`,
    modalites_abonnement = `Modalités d'abonnement`,
    visites_total = parse_number_fr(`Visites (Total)`),
    prets_total = parse_number_fr(`Prêts / Tous les doc. (Total)`),
    usagers_inscrits_total = parse_number_fr(`Usagers inscrits (Total)`),
    activites_total = parse_number_fr(`Progr. / Toutes les activités (Total)`),
    depenses_fonctionnement_total = parse_number_fr(`Dép. fonct. / Toutes les dépenses ($)`),
    visites_par_habitant = ratio_if_possible(visites_total, population_desservie),
    prets_par_habitant = ratio_if_possible(prets_total, population_desservie),
    usagers_inscrits_par_habitant = ratio_if_possible(usagers_inscrits_total, population_desservie),
    depenses_par_habitant = ratio_if_possible(depenses_fonctionnement_total, population_desservie),
    source_csv_url = csv_url,
    access_date = access_date
  ) |>
  arrange(region_administrative, bibliotheque)

summary_by_region <- bibliotheques |>
  filter(!is.na(region_administrative), !is.na(population_desservie), population_desservie > 0) |>
  group_by(region_administrative) |>
  summarise(
    n_bibliotheques = n(),
    population_desservie = sum(population_desservie, na.rm = TRUE),
    visites_total = sum(visites_total, na.rm = TRUE),
    prets_total = sum(prets_total, na.rm = TRUE),
    usagers_inscrits_total = sum(usagers_inscrits_total, na.rm = TRUE),
    activites_total = sum(activites_total, na.rm = TRUE),
    depenses_fonctionnement_total = sum(depenses_fonctionnement_total, na.rm = TRUE),
    visites_par_habitant = visites_total / population_desservie,
    prets_par_habitant = prets_total / population_desservie,
    usagers_inscrits_par_habitant = usagers_inscrits_total / population_desservie,
    depenses_par_habitant = depenses_fonctionnement_total / population_desservie,
    .groups = "drop"
  ) |>
  mutate(
    across(
      c(visites_par_habitant, prets_par_habitant, usagers_inscrits_par_habitant, depenses_par_habitant),
      ~ round(.x, 2)
    )
  ) |>
  arrange(desc(visites_par_habitant), region_administrative)

summary_by_category <- bibliotheques |>
  count(categorie_bibliotheque, name = "n_bibliotheques") |>
  mutate(pct_bibliotheques = round(100 * n_bibliotheques / sum(n_bibliotheques), 1)) |>
  arrange(desc(n_bibliotheques), categorie_bibliotheque)

top_visites_ratio <- bibliotheques |>
  filter(!is.na(visites_par_habitant), population_desservie > 0) |>
  arrange(desc(visites_par_habitant), bibliotheque) |>
  select(
    bibliotheque,
    region_administrative,
    population_desservie,
    visites_total,
    prets_total,
    depenses_fonctionnement_total,
    visites_par_habitant,
    prets_par_habitant,
    depenses_par_habitant
  ) |>
  mutate(
    across(
      c(visites_par_habitant, prets_par_habitant, depenses_par_habitant),
      ~ round(.x, 2)
    )
  )

missing_summary <- bibliotheques |>
  summarise(across(everything(), ~ sum(is.na(.x)))) |>
  pivot_longer(
    cols = everything(),
    names_to = "variable",
    values_to = "n_missing"
  ) |>
  mutate(
    n_rows = nrow(bibliotheques),
    pct_missing = round(100 * n_missing / n_rows, 2)
  ) |>
  arrange(desc(n_missing), variable)

valid_ratios <- bibliotheques |>
  filter(!is.na(population_desservie), population_desservie > 0)

dataset_summary <- tibble::tibble(
  metric = c(
    "source_page",
    "source_api",
    "csv_url",
    "dictionary_url",
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
    "n_regions",
    "n_categories",
    "population_total",
    "visites_total",
    "prets_total",
    "usagers_inscrits_total",
    "activites_total",
    "depenses_fonctionnement_total",
    "median_visites_par_habitant",
    "median_prets_par_habitant",
    "median_usagers_inscrits_par_habitant",
    "median_depenses_par_habitant",
    "n_rows_without_population"
  ),
  value = c(
    source_page,
    source_api,
    csv_url,
    dictionary_url,
    as.character(access_date),
    package$result$id,
    as.character(package$result$metadata_modified),
    resources$last_modified[resources$url == csv_url],
    as.character(resources$size[resources$url == csv_url]),
    as.character(package$result$license_title),
    as.character(nrow(resources)),
    as.character(nrow(source_data)),
    as.character(ncol(source_data)),
    as.character(nrow(bibliotheques)),
    as.character(ncol(bibliotheques)),
    as.character(n_distinct(bibliotheques$region_administrative, na.rm = TRUE)),
    as.character(n_distinct(bibliotheques$categorie_bibliotheque, na.rm = TRUE)),
    as.character(sum(bibliotheques$population_desservie, na.rm = TRUE)),
    as.character(sum(bibliotheques$visites_total, na.rm = TRUE)),
    as.character(sum(bibliotheques$prets_total, na.rm = TRUE)),
    as.character(sum(bibliotheques$usagers_inscrits_total, na.rm = TRUE)),
    as.character(sum(bibliotheques$activites_total, na.rm = TRUE)),
    as.character(sum(bibliotheques$depenses_fonctionnement_total, na.rm = TRUE)),
    as.character(round(median(valid_ratios$visites_par_habitant, na.rm = TRUE), 2)),
    as.character(round(median(valid_ratios$prets_par_habitant, na.rm = TRUE), 2)),
    as.character(round(median(valid_ratios$usagers_inscrits_par_habitant, na.rm = TRUE), 2)),
    as.character(round(median(valid_ratios$depenses_par_habitant, na.rm = TRUE), 2)),
    as.character(sum(is.na(bibliotheques$population_desservie) | bibliotheques$population_desservie <= 0))
  )
)

stopifnot(
  nrow(resources) == 19,
  nrow(source_data) == 188,
  ncol(source_data) == 262,
  nrow(bibliotheques) == 188,
  ncol(bibliotheques) == 16,
  n_distinct(bibliotheques$region_administrative, na.rm = TRUE) == 19,
  n_distinct(bibliotheques$categorie_bibliotheque, na.rm = TRUE) == 5,
  sum(is.na(bibliotheques$population_desservie) | bibliotheques$population_desservie <= 0) == 1,
  sum(bibliotheques$visites_total, na.rm = TRUE) == 59981972,
  sum(bibliotheques$prets_total, na.rm = TRUE) == 52513445
)

write_csv(resources, file.path(processed_dir, "ressources_ckan_bibliotheques.csv"))
write_csv(bibliotheques, file.path(processed_dir, "statistiques_bibliotheques_quebec_2024_selection.csv"))
write_csv(summary_by_region, file.path(processed_dir, "resume_regions_bibliotheques_2024.csv"))
write_csv(summary_by_category, file.path(processed_dir, "resume_categories_bibliotheques_2024.csv"))
write_csv(top_visites_ratio, file.path(processed_dir, "bibliotheques_top_visites_par_habitant_2024.csv"))
write_csv(missing_summary, file.path(processed_dir, "valeurs_manquantes_bibliotheques_2024.csv"))
write_csv(dataset_summary, file.path(processed_dir, "resume_bibliotheques_2024.csv"))

record_preparation("bibliotheques-quebec")
