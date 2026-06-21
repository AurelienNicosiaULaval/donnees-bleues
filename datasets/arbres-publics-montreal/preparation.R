# Préparation : arbres publics sur le territoire de Montréal
# Source officielle : Données Québec / Ville de Montréal, paquet CKAN b89fd27d-4b49-461b-8e54-fa2b34a628c4.

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

parse_source_date <- function(x) {
  as.Date(substr(as.character(x), 1, 10))
}

plausible_date <- function(x, access_date) {
  if_else(
    !is.na(x) & x >= as.Date("1900-01-01") & x <= access_date,
    x,
    as.Date(NA)
  )
}

root <- find_project_root()
raw_dir <- file.path(root, "data/raw/arbres-publics-montreal")
processed_dir <- file.path(root, "data/processed/arbres-publics-montreal")
dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(processed_dir, recursive = TRUE, showWarnings = FALSE)

access_date <- as.Date("2026-06-21")
source_page <- "https://www.donneesquebec.ca/recherche/dataset/vmtl-arbres"
source_api <- "https://www.donneesquebec.ca/recherche/api/3/action/package_show?id=vmtl-arbres"
source_montreal_page <- "https://donnees.montreal.ca/dataset/arbres"
csv_url <- "https://donnees.montreal.ca/dataset/b89fd27d-4b49-461b-8e54-fa2b34a628c4/resource/64e28fe6-ef37-437a-972d-d1d3f1f7d891/download/arbres-publics.csv"
dhp_url <- "https://donnees.montreal.ca/dataset/b89fd27d-4b49-461b-8e54-fa2b34a628c4/resource/6c217c92-63c8-49e8-a6ef-afda6121656d/download/arbres-dhp.csv"
dictionary_url <- "https://donnees.montreal.ca/dataset/b89fd27d-4b49-461b-8e54-fa2b34a628c4/resource/7fe8c742-ee64-4cca-b889-467b68e7db6a/download/dictionnaire-de-donnees-arbres-publics_rev2018.pdf"

package_json_path <- file.path(raw_dir, "package_show_arbres_publics.json")
csv_raw_path <- file.path(raw_dir, "arbres-publics.csv")

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

expected_columns <- c(
  "INV_TYPE", "EMP_NO", "ARROND", "ARROND_NOM", "Rue", "Rue_cote",
  "No_civique", "Emplacement", "Sigle", "Essence_latin", "Essence_fr",
  "Essence_ang", "DHP", "Date_Releve", "Date_Plantation", "LOCALISATION",
  "Localisation_code", "CODE_PARC", "NOM_PARC", "Rue_de", "Rue_a",
  "Distance_pave", "Distance_ligne_rue", "Stationnement_jour",
  "Stationnement_heure", "District", "Arbre_remarquable", "Code_secteur",
  "Nom_secteur", "Coord_X", "Coord_Y", "Longitude", "Latitude"
)

if (!identical(names(source_data), expected_columns)) {
  stop(
    "Structure source inattendue. Champs observés : ",
    paste(names(source_data), collapse = ", "),
    call. = FALSE
  )
}

arbres <- source_data |>
  transmute(
    inventaire_type = INV_TYPE,
    arbre_id = as.character(EMP_NO),
    arrondissement_code = as.integer(ARROND),
    arrondissement = ARROND_NOM,
    rue = Rue,
    cote_rue = Rue_cote,
    no_civique = as.integer(No_civique),
    emplacement = Emplacement,
    sigle = Sigle,
    essence_latin = Essence_latin,
    essence_fr = Essence_fr,
    essence_ang = Essence_ang,
    dhp = as.numeric(DHP),
    date_releve = parse_source_date(Date_Releve),
    date_plantation = parse_source_date(Date_Plantation),
    date_releve_plausible = plausible_date(date_releve, access_date),
    date_plantation_plausible = plausible_date(date_plantation, access_date),
    localisation = LOCALISATION,
    localisation_code = Localisation_code,
    code_parc = CODE_PARC,
    nom_parc = NOM_PARC,
    district = as.integer(District),
    arbre_remarquable = Arbre_remarquable == "O",
    code_secteur = as.integer(Code_secteur),
    nom_secteur = Nom_secteur,
    coord_x = as.numeric(Coord_X),
    coord_y = as.numeric(Coord_Y),
    longitude = as.numeric(Longitude),
    latitude = as.numeric(Latitude),
    coordonnees_disponibles = !is.na(longitude) & !is.na(latitude),
    source_csv_url = csv_url,
    access_date = access_date
  ) |>
  arrange(arrondissement, essence_fr, arbre_id)

summary_by_essence <- arbres |>
  count(essence_fr, essence_latin, name = "n_arbres") |>
  mutate(pct_arbres = round(100 * n_arbres / sum(n_arbres), 1)) |>
  arrange(desc(n_arbres), essence_fr)

summary_by_arrondissement <- arbres |>
  group_by(arrondissement) |>
  summarise(
    n_arbres = n(),
    n_essences_fr = n_distinct(essence_fr, na.rm = TRUE),
    mediane_dhp = median(dhp, na.rm = TRUE),
    n_dates_plantation_manquantes = sum(is.na(date_plantation)),
    n_coordonnees_manquantes = sum(!coordonnees_disponibles),
    n_arbres_remarquables = sum(arbre_remarquable, na.rm = TRUE),
    .groups = "drop"
  ) |>
  arrange(desc(n_arbres), arrondissement)

summary_by_emplacement <- arbres |>
  count(emplacement, name = "n_arbres") |>
  mutate(pct_arbres = round(100 * n_arbres / sum(n_arbres), 1)) |>
  arrange(desc(n_arbres), emplacement)

missing_summary <- arbres |>
  summarise(across(everything(), ~ sum(is.na(.x)))) |>
  pivot_longer(
    cols = everything(),
    names_to = "variable",
    values_to = "n_missing"
  ) |>
  mutate(
    n_rows = nrow(arbres),
    pct_missing = round(100 * n_missing / n_rows, 2)
  ) |>
  arrange(desc(n_missing), variable)

date_quality <- tibble::tibble(
  variable = c("date_releve", "date_plantation"),
  n_missing = c(sum(is.na(arbres$date_releve)), sum(is.na(arbres$date_plantation))),
  n_non_plausible = c(
    sum(!is.na(arbres$date_releve) & is.na(arbres$date_releve_plausible)),
    sum(!is.na(arbres$date_plantation) & is.na(arbres$date_plantation_plausible))
  ),
  first_plausible = c(
    as.character(min(arbres$date_releve_plausible, na.rm = TRUE)),
    as.character(min(arbres$date_plantation_plausible, na.rm = TRUE))
  ),
  last_plausible = c(
    as.character(max(arbres$date_releve_plausible, na.rm = TRUE)),
    as.character(max(arbres$date_plantation_plausible, na.rm = TRUE))
  )
)

dataset_summary <- tibble::tibble(
  metric = c(
    "source_page",
    "source_api",
    "source_montreal_page",
    "csv_url",
    "dhp_url",
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
    "n_arrondissements",
    "n_essences_fr",
    "n_essences_latin",
    "n_emplacements",
    "n_missing_coordinates",
    "n_missing_date_plantation",
    "n_missing_dhp",
    "median_dhp",
    "n_arbres_remarquables",
    "first_releve_plausible",
    "last_releve_plausible",
    "n_releve_non_plausible",
    "first_plantation_plausible",
    "last_plantation_plausible",
    "n_plantation_non_plausible"
  ),
  value = c(
    source_page,
    source_api,
    source_montreal_page,
    csv_url,
    dhp_url,
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
    as.character(nrow(arbres)),
    as.character(ncol(arbres)),
    as.character(n_distinct(arbres$arrondissement)),
    as.character(n_distinct(arbres$essence_fr, na.rm = TRUE)),
    as.character(n_distinct(arbres$essence_latin, na.rm = TRUE)),
    as.character(n_distinct(arbres$emplacement, na.rm = TRUE)),
    as.character(sum(!arbres$coordonnees_disponibles)),
    as.character(sum(is.na(arbres$date_plantation))),
    as.character(sum(is.na(arbres$dhp))),
    as.character(median(arbres$dhp, na.rm = TRUE)),
    as.character(sum(arbres$arbre_remarquable, na.rm = TRUE)),
    date_quality$first_plausible[date_quality$variable == "date_releve"],
    date_quality$last_plausible[date_quality$variable == "date_releve"],
    as.character(date_quality$n_non_plausible[date_quality$variable == "date_releve"]),
    date_quality$first_plausible[date_quality$variable == "date_plantation"],
    date_quality$last_plausible[date_quality$variable == "date_plantation"],
    as.character(date_quality$n_non_plausible[date_quality$variable == "date_plantation"])
  )
)

stopifnot(
  nrow(resources) == 6,
  nrow(arbres) > 300000,
  ncol(source_data) == 33,
  n_distinct(arbres$arrondissement) >= 10,
  n_distinct(arbres$essence_fr, na.rm = TRUE) > 500,
  sum(!arbres$coordonnees_disponibles) <= 10,
  median(arbres$dhp, na.rm = TRUE) > 0
)

write_csv(resources, file.path(processed_dir, "ressources_ckan_arbres_publics.csv"))
write_csv(arbres, file.path(processed_dir, "arbres_publics_montreal.csv"))
write_csv(summary_by_essence, file.path(processed_dir, "resume_essences_arbres_publics.csv"))
write_csv(summary_by_arrondissement, file.path(processed_dir, "resume_arrondissements_arbres_publics.csv"))
write_csv(summary_by_emplacement, file.path(processed_dir, "resume_emplacements_arbres_publics.csv"))
write_csv(missing_summary, file.path(processed_dir, "valeurs_manquantes_arbres_publics.csv"))
write_csv(date_quality, file.path(processed_dir, "qualite_dates_arbres_publics.csv"))
write_csv(dataset_summary, file.path(processed_dir, "resume_arbres_publics.csv"))
