source("R/utils_downloads.R")
# Préparer les permis, bâtiments et quartiers de la Ville de Québec.

library(dplyr)
library(janitor)
library(jsonlite)
library(purrr)
library(readr)
library(sf)
library(stringr)
library(tidyr)

source("R/utils_ckan.R")

`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0L || all(is.na(x))) y else x
}

dataset_id <- "construction-quartiers-quebec"
raw_dir <- file.path("data", "raw", dataset_id)
processed_dir <- file.path("data", "processed", dataset_id)
metadata_dir <- file.path(raw_dir, "metadata")

dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(processed_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(metadata_dir, recursive = TRUE, showWarnings = FALSE)

download_date <- as.character(Sys.Date())

resources <- tibble::tribble(
  ~source_id, ~package_id, ~resource_id, ~raw_file, ~processed_file,
  "permis", "permis-delivres-ville-de-quebec", "9555031e-cfc5-4b78-bec9-4ab84b549f67", "vdq-permis.csv", "permis_delivres_quebec.csv",
  "batiments", "empreintes-des-batiments", "0920b952-b349-4ddd-a7e3-eebf6f6b6336", "vdq-batiments.csv", "batiments_quebec.csv",
  "quartiers", "vque_9", "11b26afb-8215-4723-8dc5-78c93eec8763", "vdq-quartier.csv", "quartiers_quebec.csv"
)

get_resource_record <- function(source_id, package_id, resource_id, raw_file, processed_file) {
  response_path <- file.path(metadata_dir, paste0(package_id, "-response.json"))
  package_url <- paste0("https://www.donneesquebec.ca/recherche/api/3/action/package_show?id=", package_id)
  download_source(package_url, response_path)
  response <- jsonlite::fromJSON(response_path)
  if (!isTRUE(response$success)) stop("Réponse CKAN invalide : ", package_id, call. = FALSE)
  package <- response$result
  resource <- package$resources |>
    filter(.data$id == resource_id)

  if (nrow(resource) != 1L) {
    stop("Ressource introuvable dans Données Québec : ", resource_id, call. = FALSE)
  }

  write_json(
    package,
    file.path(metadata_dir, paste0(package_id, ".json")),
    auto_unbox = TRUE,
    pretty = TRUE,
    null = "null"
  )

  tibble(
    source_id = source_id,
    package_id = package_id,
    package_title = package$title %||% NA_character_,
    package_url = paste0("https://www.donneesquebec.ca/recherche/dataset/", package_id),
    package_notes = package$notes %||% NA_character_,
    license = package$license_title %||% NA_character_,
    package_metadata_created = package$metadata_created %||% NA_character_,
    package_metadata_modified = package$metadata_modified %||% NA_character_,
    resource_id = resource_id,
    resource_name = resource$name %||% NA_character_,
    resource_format = resource$format %||% NA_character_,
    resource_url = resource$url %||% NA_character_,
    resource_description = resource$description %||% NA_character_,
    resource_last_modified = resource$last_modified %||% NA_character_,
    resource_size_bytes = suppressWarnings(as.numeric(resource$size %||% NA_real_)),
    raw_file = file.path(raw_dir, raw_file),
    processed_file = file.path(processed_dir, processed_file),
    download_date = download_date
  )
}

resource_records <- pmap_dfr(resources, get_resource_record)

download_resource <- function(url, destination) {
  download_source(url, destination, mode = "wb", quiet = TRUE)
  destination
}

walk2(resource_records$resource_url, resource_records$raw_file, download_resource)

read_clean_csv <- function(path) {
  read_csv(
    path,
    locale = locale(encoding = "UTF-8"),
    show_col_types = FALSE
  ) |>
    clean_names()
}

raw_path <- function(source_id) {
  resource_records$raw_file[resource_records$source_id == source_id]
}

processed_path <- function(source_id) {
  resource_records$processed_file[resource_records$source_id == source_id]
}

permis <- read_clean_csv(raw_path("permis")) |>
  mutate(date_delivrance = as.Date(.data$date_delivrance))

batiments <- read_clean_csv(raw_path("batiments"))

quartiers <- read_clean_csv(raw_path("quartiers"))

write_csv(permis, processed_path("permis"))
write_csv(batiments, processed_path("batiments"))
write_csv(quartiers, processed_path("quartiers"))

wkt_to_sf <- function(data, geometry_col = "geometrie", crs = 4326) {
  if (!geometry_col %in% names(data)) {
    stop("Colonne de géométrie introuvable : ", geometry_col, call. = FALSE)
  }

  geometry <- st_as_sfc(data[[geometry_col]], crs = crs)
  attributes <- data |>
    select(-all_of(geometry_col))

  st_sf(attributes, geometry = geometry, crs = crs) |>
    st_make_valid()
}

# Les métadonnées officielles des quartiers indiquent EPSG:32187 pour les
# superficies et périmètres approximatifs. On l'utilise aussi pour les
# superficies d'empreintes calculées à partir des polygones.
metric_crs <- 32187

quartiers_sf <- wkt_to_sf(quartiers) |>
  st_transform(metric_crs) |>
  transmute(
    id_quartier = .data$id,
    nom_quartier = .data$nom,
    superficie_quartier_m2 = .data$superficie,
    perimetre_quartier_m = .data$perimetre
  )

batiments_sf <- wkt_to_sf(batiments) |>
  st_transform(metric_crs) |>
  mutate(
    superficie_batiment_m2 = as.numeric(st_area(.data$geometry)),
    geometry = st_point_on_surface(.data$geometry)
  )

permis_points <- permis |>
  mutate(.permis_row_id = row_number()) |>
  filter(!is.na(.data$longitude), !is.na(.data$latitude)) |>
  st_as_sf(
    coords = c("longitude", "latitude"),
    crs = 4326,
    remove = FALSE
  ) |>
  st_transform(metric_crs)

batiments_quartiers <- st_join(
  batiments_sf,
  quartiers_sf,
  join = st_within,
  left = TRUE
)

permis_quartiers <- st_join(
  permis_points,
  quartiers_sf,
  join = st_within,
  left = TRUE
)

permis_agreges <- permis_quartiers |>
  st_drop_geometry() |>
  filter(!is.na(.data$id_quartier)) |>
  mutate(annee_delivrance = as.integer(format(.data$date_delivrance, "%Y"))) |>
  group_by(.data$id_quartier, .data$nom_quartier) |>
  summarise(
    nombre_permis = n(),
    nombre_permis_construction_batiment_principal = sum(.data$domaine == "Construction d'un bâtiment principal", na.rm = TRUE),
    nombre_permis_renovation_agrandissement = sum(.data$domaine == "Rénovation/Agrandissement", na.rm = TRUE),
    nombre_permis_constructions_amenagements_accessoires = sum(.data$domaine == "Constructions et aménagements accessoires", na.rm = TRUE),
    nombre_permis_lotissement = sum(.data$domaine == "Lotissement", na.rm = TRUE),
    annee_min_permis = min(.data$annee_delivrance, na.rm = TRUE),
    annee_max_permis = max(.data$annee_delivrance, na.rm = TRUE),
    .groups = "drop"
  )

batiments_agreges <- batiments_quartiers |>
  st_drop_geometry() |>
  filter(!is.na(.data$id_quartier)) |>
  group_by(.data$id_quartier, .data$nom_quartier) |>
  summarise(
    nombre_batiments = n(),
    nombre_batiments_residence = sum(.data$type_batiment == "Résidence", na.rm = TRUE),
    nombre_batiments_garage_annexe_remise = sum(.data$type_batiment == "Garage - Annexe - Remise", na.rm = TRUE),
    nombre_batiments_commercial = sum(.data$type_batiment == "Bâtiment commercial", na.rm = TRUE),
    superficie_empreintes_batiments_m2 = sum(.data$superficie_batiment_m2, na.rm = TRUE),
    superficie_moyenne_batiment_m2 = mean(.data$superficie_batiment_m2, na.rm = TRUE),
    .groups = "drop"
  )

construction_quartiers <- quartiers_sf |>
  st_drop_geometry() |>
  left_join(permis_agreges, by = c("id_quartier", "nom_quartier")) |>
  left_join(batiments_agreges, by = c("id_quartier", "nom_quartier")) |>
  mutate(
    across(
      all_of(c(
        "nombre_permis",
        "nombre_permis_construction_batiment_principal",
        "nombre_permis_renovation_agrandissement",
        "nombre_permis_constructions_amenagements_accessoires",
        "nombre_permis_lotissement",
        "nombre_batiments",
        "nombre_batiments_residence",
        "nombre_batiments_garage_annexe_remise",
        "nombre_batiments_commercial"
      )),
      ~ replace_na(.x, 0)
    ),
    superficie_empreintes_batiments_m2 = replace_na(.data$superficie_empreintes_batiments_m2, 0),
    superficie_moyenne_batiment_m2 = if_else(.data$nombre_batiments > 0, .data$superficie_moyenne_batiment_m2, NA_real_),
    superficie_quartier_km2 = .data$superficie_quartier_m2 / 1e6,
    permis_par_km2 = if_else(.data$superficie_quartier_km2 > 0, .data$nombre_permis / .data$superficie_quartier_km2, NA_real_),
    batiments_par_km2 = if_else(.data$superficie_quartier_km2 > 0, .data$nombre_batiments / .data$superficie_quartier_km2, NA_real_),
    part_superficie_batie = if_else(
      .data$superficie_quartier_m2 > 0,
      .data$superficie_empreintes_batiments_m2 / .data$superficie_quartier_m2,
      NA_real_
    )
  ) |>
  arrange(.data$nom_quartier)

aggregate_path <- file.path(processed_dir, "quebec_construction_quartiers.csv")
write_csv(construction_quartiers, aggregate_path)

source_documentation <- resource_records |>
  mutate(
    n_rows = c(nrow(permis), nrow(batiments), nrow(quartiers)),
    n_cols = c(ncol(permis), ncol(batiments), ncol(quartiers)),
    simple_csv = basename(.data$processed_file)
  ) |>
  select(
    source_id,
    package_title,
    package_url,
    license,
    resource_id,
    resource_name,
    resource_format,
    resource_url,
    resource_last_modified,
    download_date,
    simple_csv,
    n_rows,
    n_cols,
    resource_description
  )

write_csv(source_documentation, file.path(processed_dir, "documentation_sources.csv"))

appariement_quartiers <- tibble(
  indicateur = c(
    "permis_lignes_source",
    "permis_sans_coordonnees",
    "permis_avec_quartier",
    "permis_sans_quartier",
    "batiments_lignes_source",
    "batiments_avec_quartier",
    "batiments_sans_quartier",
    "quartiers_source",
    "quartiers_agreges"
  ),
  valeur = c(
    nrow(permis),
    sum(is.na(permis$longitude) | is.na(permis$latitude)),
    sum(!is.na(permis_quartiers$id_quartier)),
    sum(is.na(permis_quartiers$id_quartier)),
    nrow(batiments),
    sum(!is.na(batiments_quartiers$id_quartier)),
    sum(is.na(batiments_quartiers$id_quartier)),
    nrow(quartiers),
    nrow(construction_quartiers)
  ),
  note = c(
    "Nombre de lignes dans le CSV officiel des permis.",
    "Permis sans longitude ou latitude dans le CSV officiel.",
    "Permis dont le point est situé dans un quartier officiel.",
    "Permis dont le point n'est situé dans aucun quartier officiel.",
    "Nombre de lignes dans le CSV officiel des empreintes de bâtiments.",
    "Bâtiments dont le point représentatif est situé dans un quartier officiel.",
    "Bâtiments dont le point représentatif n'est situé dans aucun quartier officiel.",
    "Nombre de quartiers dans le CSV officiel.",
    "Nombre de lignes dans le fichier agrégé par quartier."
  )
)

write_csv(appariement_quartiers, file.path(processed_dir, "appariement_quartiers_resume.csv"))

dictionnaire_variables <- tibble::tribble(
  ~fichier, ~variable, ~description, ~origine,
  "permis_delivres_quebec.csv", "numero_permis", "Numéro de permis.", "Variable officielle NUMERO_PERMIS, nom nettoyé.",
  "permis_delivres_quebec.csv", "date_delivrance", "Date de délivrance du permis.", "Variable officielle DATE_DELIVRANCE, convertie en date ISO.",
  "permis_delivres_quebec.csv", "adresse_travaux", "Adresse concernée par le permis demandé.", "Variable officielle ADRESSE_TRAVAUX, nom nettoyé.",
  "permis_delivres_quebec.csv", "domaine", "Domaine de l'intervention du permis.", "Variable officielle DOMAINE, nom nettoyé.",
  "permis_delivres_quebec.csv", "lots_impactes", "Lots concernés par la demande.", "Variable officielle LOTS_IMPACTES, nom nettoyé.",
  "permis_delivres_quebec.csv", "type_permis", "Type de permis émis.", "Variable officielle TYPE_PERMIS, nom nettoyé.",
  "permis_delivres_quebec.csv", "arrondissement", "Arrondissement publié dans le fichier des permis.", "Variable officielle ARRONDISSEMENT, nom nettoyé.",
  "permis_delivres_quebec.csv", "raison", "Libellé principal du permis.", "Variable officielle RAISON, nom nettoyé.",
  "permis_delivres_quebec.csv", "longitude", "Longitude du permis.", "Variable officielle LONGITUDE.",
  "permis_delivres_quebec.csv", "latitude", "Latitude du permis.", "Variable officielle LATITUDE.",
  "batiments_quebec.csv", "id", "Identifiant du bâtiment.", "Variable officielle ID, nom nettoyé.",
  "batiments_quebec.csv", "source_captage", "Source de captage de l'empreinte.", "Variable officielle SOURCE_CAPTAGE, nom nettoyé.",
  "batiments_quebec.csv", "type_batiment", "Type de bâtiment publié.", "Variable officielle TYPE_BATIMENT, nom nettoyé.",
  "batiments_quebec.csv", "geometrie", "Géométrie WKT de l'empreinte.", "Variable officielle GEOMETRIE, nom nettoyé.",
  "quartiers_quebec.csv", "id", "Identifiant unique du quartier.", "Variable officielle ID, nom nettoyé.",
  "quartiers_quebec.csv", "nom", "Nom du quartier.", "Variable officielle NOM, nom nettoyé.",
  "quartiers_quebec.csv", "superficie", "Superficie approximative du quartier en mètres carrés.", "Variable officielle SUPERFICIE, nom nettoyé.",
  "quartiers_quebec.csv", "perimetre", "Périmètre approximatif du quartier en mètres.", "Variable officielle PERIMETRE, nom nettoyé.",
  "quartiers_quebec.csv", "geometrie", "Géométrie WKT du quartier.", "Variable officielle GEOMETRIE, nom nettoyé.",
  "quebec_construction_quartiers.csv", "id_quartier", "Identifiant du quartier.", "Variable officielle ID du fichier quartiers, renommée pour clarifier l'agrégat.",
  "quebec_construction_quartiers.csv", "nom_quartier", "Nom du quartier.", "Variable officielle NOM du fichier quartiers, renommée pour clarifier l'agrégat.",
  "quebec_construction_quartiers.csv", "superficie_quartier_m2", "Superficie approximative du quartier en mètres carrés.", "Variable officielle SUPERFICIE du fichier quartiers.",
  "quebec_construction_quartiers.csv", "perimetre_quartier_m", "Périmètre approximatif du quartier en mètres.", "Variable officielle PERIMETRE du fichier quartiers.",
  "quebec_construction_quartiers.csv", "nombre_permis", "Nombre de permis dont les coordonnées tombent dans le quartier.", "Compte dérivé par jointure spatiale des permis aux quartiers.",
  "quebec_construction_quartiers.csv", "nombre_permis_construction_batiment_principal", "Nombre de permis avec domaine exactement égal à Construction d'un bâtiment principal.", "Compte dérivé de la variable officielle domaine.",
  "quebec_construction_quartiers.csv", "nombre_permis_renovation_agrandissement", "Nombre de permis avec domaine exactement égal à Rénovation/Agrandissement.", "Compte dérivé de la variable officielle domaine.",
  "quebec_construction_quartiers.csv", "nombre_permis_constructions_amenagements_accessoires", "Nombre de permis avec domaine exactement égal à Constructions et aménagements accessoires.", "Compte dérivé de la variable officielle domaine.",
  "quebec_construction_quartiers.csv", "nombre_permis_lotissement", "Nombre de permis avec domaine exactement égal à Lotissement.", "Compte dérivé de la variable officielle domaine.",
  "quebec_construction_quartiers.csv", "annee_min_permis", "Première année de délivrance observée parmi les permis appariés au quartier.", "Dérivé de date_delivrance.",
  "quebec_construction_quartiers.csv", "annee_max_permis", "Dernière année de délivrance observée parmi les permis appariés au quartier.", "Dérivé de date_delivrance.",
  "quebec_construction_quartiers.csv", "nombre_batiments", "Nombre d'empreintes de bâtiments dont le point représentatif tombe dans le quartier.", "Compte dérivé par jointure spatiale des bâtiments aux quartiers.",
  "quebec_construction_quartiers.csv", "nombre_batiments_residence", "Nombre de bâtiments avec type_batiment exactement égal à Résidence.", "Compte dérivé de la variable officielle type_batiment.",
  "quebec_construction_quartiers.csv", "nombre_batiments_garage_annexe_remise", "Nombre de bâtiments avec type_batiment exactement égal à Garage - Annexe - Remise.", "Compte dérivé de la variable officielle type_batiment.",
  "quebec_construction_quartiers.csv", "nombre_batiments_commercial", "Nombre de bâtiments avec type_batiment exactement égal à Bâtiment commercial.", "Compte dérivé de la variable officielle type_batiment.",
  "quebec_construction_quartiers.csv", "superficie_empreintes_batiments_m2", "Somme des superficies calculées à partir des empreintes de bâtiments.", "Dérivé des géométries officielles des bâtiments, projetées en EPSG:32187.",
  "quebec_construction_quartiers.csv", "superficie_moyenne_batiment_m2", "Superficie moyenne des empreintes de bâtiments appariées au quartier.", "Dérivé des géométries officielles des bâtiments, projetées en EPSG:32187.",
  "quebec_construction_quartiers.csv", "superficie_quartier_km2", "Superficie du quartier en kilomètres carrés.", "Dérivé de superficie_quartier_m2.",
  "quebec_construction_quartiers.csv", "permis_par_km2", "Nombre de permis par kilomètre carré de quartier.", "Dérivé de nombre_permis et superficie_quartier_km2.",
  "quebec_construction_quartiers.csv", "batiments_par_km2", "Nombre de bâtiments par kilomètre carré de quartier.", "Dérivé de nombre_batiments et superficie_quartier_km2.",
  "quebec_construction_quartiers.csv", "part_superficie_batie", "Part de la superficie de quartier occupée par les empreintes de bâtiments.", "Dérivé de superficie_empreintes_batiments_m2 et superficie_quartier_m2."
)

write_csv(dictionnaire_variables, file.path(processed_dir, "dictionnaire_variables.csv"))

message("Fichiers bruts : ", raw_dir)
message("Fichiers préparés : ", processed_dir)
message("Agrégat par quartier : ", aggregate_path)

record_preparation("construction-quartiers-quebec")
