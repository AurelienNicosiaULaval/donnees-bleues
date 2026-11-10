# Recalculer les agrégats de quartier à partir des trois copies API.
library(dplyr)
library(janitor)
library(readr)
library(sf)
library(tidyr)

preparer_construction_api <- function(fichiers) {
  if (!identical(names(fichiers), c('permis', 'batiments', 'quartiers')))
    stop('Les trois sources de construction sont requises.', call. = FALSE)
  lire <- function(path) readr::read_csv(path, show_col_types = FALSE) |> janitor::clean_names()
  permis <- lire(fichiers[['permis']]) |> mutate(date_delivrance = as.Date(date_delivrance))
  batiments <- lire(fichiers[['batiments']])
  quartiers <- lire(fichiers[['quartiers']])
  if (!all(c('date_delivrance','domaine','longitude','latitude') %in% names(permis)) ||
      !all(c('id','type_batiment','geometrie') %in% names(batiments)) ||
      !all(c('id','nom','superficie','perimetre','geometrie') %in% names(quartiers)) ||
      !nrow(permis) || !nrow(batiments) || !nrow(quartiers) || anyDuplicated(quartiers$id))
    stop('Schéma ou identifiants des sources de construction invalides.', call. = FALSE)

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
  construction_quartiers
}
