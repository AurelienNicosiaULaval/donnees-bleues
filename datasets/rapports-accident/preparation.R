source("R/utils_downloads.R")
# Préparation : rapports d'accident 2022.
# Source officielle : Données Québec / Société de l'assurance automobile du Québec,
# paquet CKAN 8dd0ab9b-d45d-4526-9256-c598fbc4ff3a.

library(dplyr)
library(jsonlite)
library(readr)
library(stringr)
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

map_values <- function(x, mapping) {
  x <- as.character(x)
  mapped <- unname(mapping[x])
  if_else(is.na(mapped), x, mapped)
}

trim_code <- function(x) {
  x <- str_squish(as.character(x))
  na_if(x, "")
}

extract_region_code <- function(x) {
  str_match(x, "\\(([0-9]{2})\\)$")[, 2]
}

extract_region_name <- function(x) {
  str_squish(str_remove(x, "\\s*\\([0-9]{2}\\)$"))
}

root <- find_project_root()
raw_dir <- file.path(root, "data/raw/rapports-accident")
processed_dir <- file.path(root, "data/processed/rapports-accident")
dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(processed_dir, recursive = TRUE, showWarnings = FALSE)

access_date <- Sys.Date()
source_page <- "https://www.donneesquebec.ca/recherche/dataset/rapports-d-accident"
source_api <- "https://www.donneesquebec.ca/recherche/api/3/action/package_show?id=rapports-d-accident"

package_json_path <- file.path(raw_dir, "package_show_rapports_accident.json")
documentation_pdf_path <- file.path(raw_dir, "rapports-accident-documentation.pdf")
csv_raw_path <- file.path(raw_dir, "Rapport_Accident_2022.csv")

download_source(source_api, package_json_path, mode = "wb", quiet = TRUE)
package <- fromJSON(package_json_path, flatten = TRUE)
if (!isTRUE(package$success)) {
  stop("L'API CKAN n'a pas retourné success = TRUE.", call. = FALSE)
}

resources <- package$result$resources |>
  transmute(
    resource_id = id,
    resource_name = name,
    format = toupper(format),
    url = url,
    last_modified = as.character(last_modified),
    metadata_modified = as.character(metadata_modified),
    size = suppressWarnings(as.numeric(size))
  )

documentation_url <- resources |>
  filter(format == "PDF", str_detect(resource_name, regex("documentation", ignore_case = TRUE))) |>
  pull(url)
csv_url <- resources |>
  filter(format == "CSV", str_detect(resource_name, "2022")) |>
  pull(url)

if (length(documentation_url) != 1L || length(csv_url) != 1L) {
  stop("Impossible d'identifier de façon unique la documentation PDF ou le CSV 2022.", call. = FALSE)
}

download_source(documentation_url, documentation_pdf_path, mode = "wb", quiet = TRUE)
download_source(csv_url, csv_raw_path, mode = "wb", quiet = TRUE)

source_data <- read_csv(
  csv_raw_path,
  locale = locale(encoding = "UTF-8"),
  col_types = cols(.default = col_character()),
  show_col_types = FALSE
)

required_columns <- c(
  "AN",
  "NO_SEQ_COLL",
  "MS_ACCDN",
  "HR_ACCDN",
  "JR_SEMN_ACCDN",
  "GRAVITE",
  "NB_VICTIMES_TOTAL",
  "NB_VEH_IMPLIQUES_ACCDN",
  "REG_ADM",
  "VITESSE_AUTOR",
  "CD_GENRE_ACCDN",
  "CD_ETAT_SURFC",
  "CD_ECLRM",
  "CD_ENVRN_ACCDN",
  "CD_CATEG_ROUTE",
  "CD_ASPCT_ROUTE",
  "CD_LOCLN_ACCDN",
  "CD_CONFG_ROUTE",
  "CD_ZON_TRAVX_ROUTR",
  "CD_COND_METEO",
  "IND_AUTO_CAMION_LEGER",
  "IND_VEH_LOURD",
  "IND_MOTO_CYCLO",
  "IND_VELO",
  "IND_PIETON"
)
missing_columns <- setdiff(required_columns, names(source_data))
if (length(missing_columns) > 0L) {
  stop("Champs source absents : ", paste(missing_columns, collapse = ", "), call. = FALSE)
}

month_labels <- c(
  "01" = "Janvier",
  "02" = "Février",
  "03" = "Mars",
  "04" = "Avril",
  "05" = "Mai",
  "06" = "Juin",
  "07" = "Juillet",
  "08" = "Août",
  "09" = "Septembre",
  "10" = "Octobre",
  "11" = "Novembre",
  "12" = "Décembre"
)
week_labels <- c("SEM" = "Lundi au vendredi", "FDS" = "Samedi ou dimanche")
victim_code_labels <- c("0" = "Aucune victime", "1" = "1 victime", "2" = "2 victimes", "9" = "3 victimes ou plus")
vehicle_code_labels <- c("1" = "1 véhicule", "2" = "2 véhicules", "9" = "3 véhicules ou plus")
surface_labels <- c(
  "11" = "Sèche",
  "12" = "Mouillée",
  "13" = "Accumulation d'eau",
  "14" = "Sable ou gravier",
  "15" = "Gadoue ou neige fondante",
  "16" = "Enneigée",
  "17" = "Neige durcie",
  "18" = "Glacée",
  "19" = "Boueuse",
  "20" = "Huileuse",
  "99" = "Autre"
)
light_labels <- c(
  "1" = "Jour et clarté",
  "2" = "Jour et demi-obscurité",
  "3" = "Nuit et chemin éclairé",
  "4" = "Nuit et chemin non éclairé"
)
environment_labels <- c(
  "1" = "Scolaire",
  "2" = "Résidentiel",
  "3" = "Affaires ou commercial",
  "4" = "Industriel ou manufacturier",
  "5" = "Rural",
  "6" = "Forestier",
  "9" = "Autre"
)
road_category_labels <- c("1" = "Chemin public", "2" = "Hors chemin public")
location_labels <- c(
  "12" = "En intersection ou carrefour giratoire",
  "33" = "Près d'une intersection",
  "34" = "Entre intersections",
  "40" = "Centre commercial",
  "69" = "Pont",
  "99" = "Autres"
)
configuration_labels <- c(
  "1" = "Sens unique",
  "23" = "Deux sens",
  "45" = "Séparée par aménagement",
  "9" = "Autre"
)
weather_labels <- c(
  "11" = "Clair",
  "12" = "Couvert",
  "13" = "Brouillard ou brume",
  "14" = "Pluie ou bruine",
  "15" = "Averse",
  "16" = "Vent fort",
  "17" = "Neige ou grêle",
  "18" = "Poudrerie ou tempête de neige",
  "19" = "Verglas",
  "99" = "Autre"
)
binary_labels <- c("O" = "Oui", "N" = "Non")

accidents <- source_data |>
  transmute(
    annee = as.integer(AN),
    identifiant_accident = NO_SEQ_COLL,
    mois_code = trim_code(MS_ACCDN),
    mois = factor(map_values(mois_code, month_labels), levels = unname(month_labels), ordered = TRUE),
    plage_horaire = trim_code(HR_ACCDN),
    jour_semaine_code = trim_code(JR_SEMN_ACCDN),
    type_jour = map_values(jour_semaine_code, week_labels),
    gravite = GRAVITE,
    accident_avec_victime = gravite %in% c("Mortel ou grave", "Léger"),
    accident_mortel_ou_grave = gravite == "Mortel ou grave",
    victimes_code = trim_code(NB_VICTIMES_TOTAL),
    victimes_categorie = map_values(victimes_code, victim_code_labels),
    vehicules_code = trim_code(NB_VEH_IMPLIQUES_ACCDN),
    vehicules_categorie = map_values(vehicules_code, vehicle_code_labels),
    region_administrative = REG_ADM,
    region_code = extract_region_code(REG_ADM),
    region_nom = extract_region_name(REG_ADM),
    vitesse_autorisee = trim_code(VITESSE_AUTOR),
    genre_accident = CD_GENRE_ACCDN,
    surface_code = trim_code(CD_ETAT_SURFC),
    surface = map_values(surface_code, surface_labels),
    eclairement_code = trim_code(CD_ECLRM),
    eclairement = map_values(eclairement_code, light_labels),
    environnement_code = trim_code(CD_ENVRN_ACCDN),
    environnement = map_values(environnement_code, environment_labels),
    categorie_route_code = trim_code(CD_CATEG_ROUTE),
    categorie_route = map_values(categorie_route_code, road_category_labels),
    aspect_route = CD_ASPCT_ROUTE,
    localisation_code = trim_code(CD_LOCLN_ACCDN),
    localisation = map_values(localisation_code, location_labels),
    configuration_code = trim_code(CD_CONFG_ROUTE),
    configuration_route = map_values(configuration_code, configuration_labels),
    zone_travaux = if_else(!is.na(trim_code(CD_ZON_TRAVX_ROUTR)) & trim_code(CD_ZON_TRAVX_ROUTR) == "O", "Oui", "Non ou non précisé"),
    meteo_code = trim_code(CD_COND_METEO),
    meteo = map_values(meteo_code, weather_labels),
    auto_camion_leger = map_values(trim_code(IND_AUTO_CAMION_LEGER), binary_labels),
    vehicule_lourd = map_values(trim_code(IND_VEH_LOURD), binary_labels),
    moto_cyclo = map_values(trim_code(IND_MOTO_CYCLO), binary_labels),
    velo = map_values(trim_code(IND_VELO), binary_labels),
    pieton = map_values(trim_code(IND_PIETON), binary_labels),
    source_csv_url = csv_url,
    access_date = access_date
  ) |>
  arrange(identifiant_accident)

summary_by_gravity <- accidents |>
  count(gravite, name = "n_accidents") |>
  mutate(pct_accidents = round(100 * n_accidents / sum(n_accidents), 1)) |>
  arrange(desc(n_accidents), gravite)

summary_by_month <- accidents |>
  group_by(mois_code, mois) |>
  summarise(
    n_accidents = n(),
    n_accidents_avec_victime = sum(accident_avec_victime, na.rm = TRUE),
    n_accidents_mortels_ou_graves = sum(accident_mortel_ou_grave, na.rm = TRUE),
    pct_accidents_avec_victime = round(100 * n_accidents_avec_victime / n_accidents, 1),
    pct_accidents_mortels_ou_graves = round(100 * n_accidents_mortels_ou_graves / n_accidents, 2),
    .groups = "drop"
  ) |>
  arrange(mois_code)

summary_by_region <- accidents |>
  group_by(region_code, region_nom, region_administrative) |>
  summarise(
    n_accidents = n(),
    n_accidents_avec_victime = sum(accident_avec_victime, na.rm = TRUE),
    n_accidents_mortels_ou_graves = sum(accident_mortel_ou_grave, na.rm = TRUE),
    pct_accidents_avec_victime = round(100 * n_accidents_avec_victime / n_accidents, 1),
    pct_accidents_mortels_ou_graves = round(100 * n_accidents_mortels_ou_graves / n_accidents, 2),
    .groups = "drop"
  ) |>
  arrange(desc(n_accidents), region_code)

summary_by_weather <- accidents |>
  group_by(meteo_code, meteo) |>
  summarise(
    n_accidents = n(),
    n_accidents_avec_victime = sum(accident_avec_victime, na.rm = TRUE),
    n_accidents_mortels_ou_graves = sum(accident_mortel_ou_grave, na.rm = TRUE),
    pct_accidents = round(100 * n_accidents / nrow(accidents), 1),
    pct_accidents_avec_victime = round(100 * n_accidents_avec_victime / n_accidents, 1),
    .groups = "drop"
  ) |>
  arrange(desc(n_accidents), meteo_code)

summary_by_road_context <- accidents |>
  group_by(surface, eclairement) |>
  summarise(
    n_accidents = n(),
    n_accidents_avec_victime = sum(accident_avec_victime, na.rm = TRUE),
    pct_accidents_avec_victime = round(100 * n_accidents_avec_victime / n_accidents, 1),
    .groups = "drop"
  ) |>
  arrange(desc(n_accidents), surface, eclairement)

summary_indicators <- tibble::tibble(
  indicateur = c("auto_camion_leger", "vehicule_lourd", "moto_cyclo", "velo", "pieton", "zone_travaux"),
  n_accidents = c(
    sum(accidents$auto_camion_leger == "Oui", na.rm = TRUE),
    sum(accidents$vehicule_lourd == "Oui", na.rm = TRUE),
    sum(accidents$moto_cyclo == "Oui", na.rm = TRUE),
    sum(accidents$velo == "Oui", na.rm = TRUE),
    sum(accidents$pieton == "Oui", na.rm = TRUE),
    sum(accidents$zone_travaux == "Oui", na.rm = TRUE)
  )
) |>
  mutate(pct_accidents = round(100 * n_accidents / nrow(accidents), 1)) |>
  arrange(desc(n_accidents))

missing_summary <- accidents |>
  summarise(across(everything(), ~ sum(is.na(.x)))) |>
  pivot_longer(
    cols = everything(),
    names_to = "variable",
    values_to = "n_missing"
  ) |>
  mutate(
    n_rows = nrow(accidents),
    pct_missing = round(100 * n_missing / n_rows, 2)
  ) |>
  arrange(desc(n_missing), variable)

dataset_summary <- tibble::tibble(
  metric = c(
    "source_page",
    "source_api",
    "csv_url",
    "documentation_url",
    "access_date",
    "package_id",
    "metadata_modified",
    "csv_resource_metadata_modified",
    "documentation_resource_modified",
    "license_title",
    "n_resources_ckan",
    "n_csv_resources",
    "n_rows_source",
    "n_columns_source",
    "n_rows_prepared",
    "n_columns_prepared",
    "n_regions",
    "n_gravity_levels",
    "n_accidents_avec_victime",
    "pct_accidents_avec_victime",
    "n_accidents_mortels_ou_graves",
    "pct_accidents_mortels_ou_graves",
    "n_accidents_code_3_victimes_ou_plus",
    "n_accidents_code_3_vehicules_ou_plus",
    "n_accidents_velo",
    "n_accidents_pieton",
    "n_accidents_zone_travaux",
    "raw_csv_size_bytes",
    "documentation_pdf_size_bytes"
  ),
  value = c(
    source_page,
    source_api,
    csv_url,
    documentation_url,
    as.character(access_date),
    package$result$id,
    as.character(package$result$metadata_modified),
    as.character(resources$metadata_modified[resources$url == csv_url]),
    as.character(resources$last_modified[resources$url == documentation_url]),
    as.character(package$result$license_title),
    as.character(nrow(resources)),
    as.character(sum(resources$format == "CSV")),
    as.character(nrow(source_data)),
    as.character(ncol(source_data)),
    as.character(nrow(accidents)),
    as.character(ncol(accidents)),
    as.character(n_distinct(accidents$region_administrative, na.rm = TRUE)),
    as.character(n_distinct(accidents$gravite, na.rm = TRUE)),
    as.character(sum(accidents$accident_avec_victime, na.rm = TRUE)),
    as.character(round(100 * mean(accidents$accident_avec_victime, na.rm = TRUE), 1)),
    as.character(sum(accidents$accident_mortel_ou_grave, na.rm = TRUE)),
    as.character(round(100 * mean(accidents$accident_mortel_ou_grave, na.rm = TRUE), 2)),
    as.character(sum(accidents$victimes_code == "9", na.rm = TRUE)),
    as.character(sum(accidents$vehicules_code == "9", na.rm = TRUE)),
    as.character(sum(accidents$velo == "Oui", na.rm = TRUE)),
    as.character(sum(accidents$pieton == "Oui", na.rm = TRUE)),
    as.character(sum(accidents$zone_travaux == "Oui", na.rm = TRUE)),
    as.character(file.info(csv_raw_path)$size),
    as.character(file.info(documentation_pdf_path)$size)
  )
)

stopifnot(
  nrow(resources) == 13,
  sum(resources$format == "CSV") == 12,
  nrow(source_data) == 108186,
  ncol(source_data) == 25,
  nrow(accidents) == 108186,
  ncol(accidents) == 42,
  n_distinct(accidents$region_administrative, na.rm = TRUE) == 17,
  n_distinct(accidents$gravite, na.rm = TRUE) == 4,
  sum(accidents$accident_avec_victime, na.rm = TRUE) == 22498,
  sum(accidents$accident_mortel_ou_grave, na.rm = TRUE) == 1397
)

write_csv(resources, file.path(processed_dir, "ressources_ckan_rapports_accident.csv"))
write_csv(accidents, file.path(processed_dir, "rapports_accident_2022_prepares.csv"))
write_csv(summary_by_gravity, file.path(processed_dir, "resume_gravite_2022.csv"))
write_csv(summary_by_month, file.path(processed_dir, "resume_mois_2022.csv"))
write_csv(summary_by_region, file.path(processed_dir, "resume_regions_2022.csv"))
write_csv(summary_by_weather, file.path(processed_dir, "resume_meteo_2022.csv"))
write_csv(summary_by_road_context, file.path(processed_dir, "resume_surface_eclairement_2022.csv"))
write_csv(summary_indicators, file.path(processed_dir, "resume_indicateurs_2022.csv"))
write_csv(missing_summary, file.path(processed_dir, "valeurs_manquantes_2022.csv"))
write_csv(dataset_summary, file.path(processed_dir, "resume_rapports_accident_2022.csv"))

record_preparation("rapports-accident")
