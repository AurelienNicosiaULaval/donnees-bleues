# Préparation : Profil financier des municipalités locales
# Source officielle : Données Québec, paquet CKAN b34de345-5bfe-4db2-a714-ed239a0c0b81.

library(dplyr)
library(jsonlite)
library(readr)
library(stringr)
library(tidyr)

raw_dir <- "data/raw/budgets-municipaux-quebec"
processed_dir <- "data/processed/budgets-municipaux-quebec"
dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(processed_dir, recursive = TRUE, showWarnings = FALSE)

access_date <- "2026-06-21"
source_page <- "https://www.donneesquebec.ca/recherche/dataset/profil-financier-des-municipalites-locales"
quebec_page <- "https://www.quebec.ca/gouvernement/gestion-municipale/finances-fiscalite-municipales/information-financiere/publications-financieres/profil-financier"
package_api <- "https://www.donneesquebec.ca/recherche/api/3/action/package_show?id=profil-financier-des-municipalites-locales"
csv_url <- "https://mamh.gouv.qc.ca/fichiersdonneesouvertes/PF-2024-2025.csv"
postes_url <- "https://mamh.gouv.qc.ca/fichiersdonneesouvertes/PF-2024-2025-DescriptionPoste.csv"

package_json_path <- file.path(raw_dir, "package_show_profil_financier_municipalites.json")
csv_raw_path <- file.path(raw_dir, "PF-2024-2025.csv")
postes_raw_path <- file.path(raw_dir, "PF-2024-2025-DescriptionPoste.csv")

download.file(package_api, package_json_path, mode = "wb", quiet = TRUE)
download.file(csv_url, csv_raw_path, mode = "wb", quiet = TRUE)
download.file(postes_url, postes_raw_path, mode = "wb", quiet = TRUE)

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

selected_resources <- resources |>
  filter(url %in% c(csv_url, postes_url))

source_data <- read_csv(
  csv_raw_path,
  show_col_types = FALSE,
  locale = locale(encoding = "UTF-8")
)

postes_raw <- read_csv(
  postes_raw_path,
  show_col_types = FALSE,
  locale = locale(encoding = "UTF-8")
)

postes <- postes_raw |>
  transmute(
    code_poste = `Code de postes`,
    sujet = Sujet,
    facettes = `Facettes (exercice - type de données - consolidation - compétences - spécifique)`,
    type_indicateur = str_extract(
      sujet,
      "Numérateurs|Dénominateurs|Ratios|Indices"
    ),
    libelle_court = sujet |>
      str_remove("^Profil financier - ") |>
      str_remove("^(Numérateurs|Dénominateurs|Ratios|Indices) - "),
    est_comparatif = str_starts(code_poste, "FIALC")
  )

financial_cols <- postes |>
  filter(str_starts(code_poste, "FIALX")) |>
  pull(code_poste) |>
  intersect(names(source_data))

municipalites <- source_data |>
  transmute(
    annee_edition = as.integer(an_edition),
    annee_donnee = as.integer(an_donnee),
    code_geographique = as.character(cod_geo),
    municipalite = nom_organisme,
    designation_organisme = desi_org,
    code_mrc = as.character(cod_mrc),
    mrc = nom_mrc,
    code_communaute_metropolitaine = as.character(cod_cm),
    communaute_metropolitaine = nom_cm,
    code_region_administrative = as.character(cod_ra),
    region_administrative = nom_ra,
    type_organisme = type_org,
    population = as.numeric(population),
    code_classe_population = as.character(cod_cp),
    classe_population = desc_cp,
    across(all_of(financial_cols), as.numeric),
    source_csv_url = csv_url,
    access_date = access_date
  ) |>
  arrange(code_geographique)

profil_long <- municipalites |>
  pivot_longer(
    cols = all_of(financial_cols),
    names_to = "code_poste",
    values_to = "valeur"
  ) |>
  left_join(postes, by = "code_poste") |>
  arrange(code_geographique, code_poste)

missing_summary <- municipalites |>
  summarise(across(everything(), ~ sum(is.na(.x)))) |>
  pivot_longer(
    cols = everything(),
    names_to = "variable",
    values_to = "n_missing"
  ) |>
  mutate(
    n_rows = nrow(municipalites),
    pct_missing = round(100 * n_missing / n_rows, 2)
  ) |>
  arrange(desc(n_missing), variable)

resume_classes_population <- municipalites |>
  mutate(
    classe_population = replace_na(classe_population, "Classe non publiée")
  ) |>
  group_by(code_classe_population, classe_population) |>
  summarise(
    n_municipalites = n(),
    population_totale = sum(population, na.rm = TRUE),
    population_mediane = median(population, na.rm = TRUE),
    rfu_mediane = median(FIALX01959, na.rm = TRUE),
    part_residentielle_mediane = median(FIALX02005, na.rm = TRUE),
    part_industrielle_commerciale_mediane = median(FIALX02006, na.rm = TRUE),
    part_agricole_mediane = median(FIALX02007, na.rm = TRUE),
    evaluation_moyenne_logement_mediane = median(FIALX02010, na.rm = TRUE),
    indice_rfu_median = median(FIALX02097, na.rm = TRUE),
    .groups = "drop"
  ) |>
  arrange(code_classe_population)

resume_regions <- municipalites |>
  group_by(code_region_administrative, region_administrative) |>
  summarise(
    n_municipalites = n(),
    population_totale = sum(population, na.rm = TRUE),
    population_mediane = median(population, na.rm = TRUE),
    rfu_mediane = median(FIALX01959, na.rm = TRUE),
    part_residentielle_mediane = median(FIALX02005, na.rm = TRUE),
    part_industrielle_commerciale_mediane = median(FIALX02006, na.rm = TRUE),
    part_agricole_mediane = median(FIALX02007, na.rm = TRUE),
    evaluation_moyenne_logement_mediane = median(FIALX02010, na.rm = TRUE),
    indice_rfu_median = median(FIALX02097, na.rm = TRUE),
    .groups = "drop"
  ) |>
  arrange(code_region_administrative)

municipalites_indice_rfu_eleve <- municipalites |>
  filter(!is.na(FIALX02097)) |>
  arrange(desc(FIALX02097), municipalite) |>
  slice_head(n = 20) |>
  select(
    code_geographique,
    municipalite,
    region_administrative,
    classe_population,
    population,
    indice_rfu = FIALX02097,
    rfu = FIALX01959,
    rfu_par_unite = FIALX02011
  )

dataset_summary <- tibble::tibble(
  metric = c(
    "source_page",
    "quebec_page",
    "package_api",
    "csv_url",
    "postes_url",
    "access_date",
    "package_id",
    "metadata_modified",
    "csv_resource_last_modified",
    "postes_resource_last_modified",
    "n_resources_ckan",
    "n_resources_selected",
    "n_rows_source",
    "n_columns_source",
    "n_rows_long",
    "n_financial_indicators",
    "n_municipalities",
    "n_regions",
    "n_mrc",
    "n_population_classes_published",
    "n_population_class_missing",
    "population_total",
    "population_min",
    "population_max"
  ),
  value = c(
    source_page,
    quebec_page,
    package_api,
    csv_url,
    postes_url,
    access_date,
    package$result$id,
    as.character(package$result$metadata_modified),
    selected_resources$last_modified[selected_resources$url == csv_url],
    selected_resources$last_modified[selected_resources$url == postes_url],
    as.character(nrow(resources)),
    as.character(nrow(selected_resources)),
    as.character(nrow(source_data)),
    as.character(ncol(source_data)),
    as.character(nrow(profil_long)),
    as.character(length(financial_cols)),
    as.character(nrow(municipalites)),
    as.character(n_distinct(municipalites$region_administrative, na.rm = TRUE)),
    as.character(n_distinct(municipalites$mrc, na.rm = TRUE)),
    as.character(n_distinct(municipalites$classe_population, na.rm = TRUE)),
    as.character(sum(is.na(municipalites$classe_population))),
    as.character(sum(municipalites$population, na.rm = TRUE)),
    as.character(min(municipalites$population, na.rm = TRUE)),
    as.character(max(municipalites$population, na.rm = TRUE))
  )
)

stopifnot(
  nrow(resources) == 215,
  nrow(selected_resources) == 2,
  nrow(source_data) == 1105,
  ncol(source_data) == 29,
  nrow(postes) == 21,
  length(financial_cols) == 14,
  nrow(municipalites) == 1105,
  nrow(profil_long) == 15470,
  n_distinct(municipalites$region_administrative, na.rm = TRUE) == 17,
  n_distinct(municipalites$mrc, na.rm = TRUE) == 87,
  n_distinct(municipalites$classe_population, na.rm = TRUE) == 5,
  sum(is.na(municipalites$classe_population)) == 2,
  sum(municipalites$population, na.rm = TRUE) == 8979690,
  max(municipalites$population, na.rm = TRUE) == 1948747
)

write_csv(
  municipalites,
  file.path(processed_dir, "profil_financier_municipalites_2025.csv")
)

write_csv(
  profil_long,
  file.path(processed_dir, "profil_financier_municipalites_long_2025.csv")
)

write_csv(
  postes,
  file.path(processed_dir, "dictionnaire_postes_profil_financier_2025.csv")
)

write_csv(
  resources,
  file.path(processed_dir, "ressources_profil_financier_municipalites.csv")
)

write_csv(
  selected_resources,
  file.path(processed_dir, "ressources_selectionnees_profil_financier_2025.csv")
)

write_csv(
  missing_summary,
  file.path(processed_dir, "valeurs_manquantes_profil_financier_2025.csv")
)

write_csv(
  resume_classes_population,
  file.path(processed_dir, "resume_classes_population_2025.csv")
)

write_csv(
  resume_regions,
  file.path(processed_dir, "resume_regions_profil_financier_2025.csv")
)

write_csv(
  municipalites_indice_rfu_eleve,
  file.path(processed_dir, "municipalites_indice_rfu_eleve_2025.csv")
)

write_csv(
  dataset_summary,
  file.path(processed_dir, "resume_profil_financier_municipalites_2025.csv")
)

message("Source : ", source_page)
message("API CKAN : ", package_api)
message("Fichier préparé : ", file.path(processed_dir, "profil_financier_municipalites_2025.csv"))
message("Municipalités préparées : ", nrow(municipalites))
message("Indicateurs financiers municipaux : ", length(financial_cols))
message("Ressources CKAN documentées : ", nrow(resources))
