# Préparation : Localisation des établissements d'enseignement au Québec
# Source officielle : Données Québec, paquet CKAN 2d3b5cf8-b347-49c7-ad3b-bd6a9c15e443.

library(dplyr)
library(purrr)
library(readr)
library(stringr)
library(tidyr)

raw_dir <- "data/raw/etablissements-enseignement"
processed_dir <- "data/processed/etablissements-enseignement"
dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(processed_dir, recursive = TRUE, showWarnings = FALSE)

source_page <- "https://www.donneesquebec.ca/recherche/dataset/localisation-des-etablissements-d-enseignement-du-reseau-scolaire-au-quebec"
package_api <- "https://www.donneesquebec.ca/recherche/api/3/action/package_show?id=localisation-des-etablissements-d-enseignement-du-reseau-scolaire-au-quebec"

resources <- tibble::tribble(
  ~source_resource, ~resource_label, ~network_category, ~unit_kind, ~expected_rows, ~file_name, ~url,
  "collegial", "Établissements collégiaux", "Collégial", "Établissement", 330L, "es_collegial.csv", "https://www.donneesquebec.ca/recherche/dataset/2d3b5cf8-b347-49c7-ad3b-bd6a9c15e443/resource/13aa95e2-22a3-4f20-878a-47dbf3480338/download/es_collegial.csv",
  "universitaire", "Établissements universitaires", "Universitaire", "Établissement", 24L, "es_universitaire.csv", "https://www.donneesquebec.ca/recherche/dataset/2d3b5cf8-b347-49c7-ad3b-bd6a9c15e443/resource/fc341512-12f8-431d-9225-d6b0c09c05cd/download/es_universitaire.csv",
  "gouvernemental", "Établissements gouvernementaux", "Gouvernemental", "Établissement", 39L, "pps_gouvernemental.csv", "https://www.donneesquebec.ca/recherche/dataset/2d3b5cf8-b347-49c7-ad3b-bd6a9c15e443/resource/881849c6-9cde-46e5-a3b4-ea131e603962/download/pps_gouvernemental.csv",
  "prive_etablissement", "Établissements privés", "Privé", "Établissement", 256L, "pps_prive_etablissement.csv", "https://www.donneesquebec.ca/recherche/dataset/2d3b5cf8-b347-49c7-ad3b-bd6a9c15e443/resource/83aae1b5-87b5-4e3d-9074-c0d4778fe812/download/pps_prive_etablissement.csv",
  "prive_installation", "Installations privées", "Privé", "Installation", 361L, "pps_prive_installation.csv", "https://www.donneesquebec.ca/recherche/dataset/2d3b5cf8-b347-49c7-ad3b-bd6a9c15e443/resource/e22aa6f1-c4ff-4896-9534-6fa65133b3e9/download/pps_prive_installation.csv",
  "public_ecole", "Écoles publiques", "Public", "Lien école-immeuble", 5466L, "pps_public_ecole.csv", "https://www.donneesquebec.ca/recherche/dataset/2d3b5cf8-b347-49c7-ad3b-bd6a9c15e443/resource/c6640a54-bc4b-43ec-864e-6c325dce61bc/download/pps_public_ecole.csv",
  "public_immeuble", "Immeubles publics", "Public", "Immeuble", 4740L, "pps_public_immeuble.csv", "https://www.donneesquebec.ca/recherche/dataset/2d3b5cf8-b347-49c7-ad3b-bd6a9c15e443/resource/6c444597-1803-4263-a6fd-a3e814df4a03/download/pps_public_immeuble.csv",
  "ssocial_cs", "Sièges sociaux CSS et CS", "Public", "Siège social CSS ou CS", 72L, "pps_public_ssocial_cs.csv", "https://www.donneesquebec.ca/recherche/dataset/2d3b5cf8-b347-49c7-ad3b-bd6a9c15e443/resource/af51e052-dc4e-4d36-b341-09f83ebce263/download/pps_public_ssocial_cs.csv",
  "ssocial_org", "Sièges sociaux organismes", "Public", "Siège social organisme", 2779L, "pps_public_ssocial_org.csv", "https://www.donneesquebec.ca/recherche/dataset/2d3b5cf8-b347-49c7-ad3b-bd6a9c15e443/resource/fbcb0e03-1f1a-4467-a6f8-2c275dc0056d/download/pps_public_ssocial_org.csv"
)

download_one <- function(url, file_name) {
  path <- file.path(raw_dir, file_name)
  download.file(url, path, mode = "wb", quiet = TRUE)
  path
}

resources <- resources |>
  mutate(raw_path = map2_chr(url, file_name, download_one))

value_from <- function(data, candidates) {
  column <- intersect(candidates, names(data))
  if (length(column) == 0L) {
    return(rep(NA_character_, nrow(data)))
  }
  as.character(data[[column[[1]]]])
}

num_from <- function(data, candidates) {
  parse_number(value_from(data, candidates), locale = locale(decimal_mark = "."))
}

standardize_one <- function(raw_path, source_resource, resource_label, network_category, unit_kind) {
  data <- read_csv(
    raw_path,
    col_types = cols(.default = col_character()),
    na = c("", "NA", "N/A"),
    show_col_types = FALSE
  )

  nom_organisme <- value_from(data, c("NOM_OFFCL_ORGNS", "NOM_OFFCL"))
  nom_immeuble <- value_from(data, c("NOM_IMM", "NOM_OFFCL_IMM"))

  tibble(
    source_resource = source_resource,
    resource_label = resource_label,
    network_category = network_category,
    unit_kind = unit_kind,
    source_row = seq_len(nrow(data)),
    date_maj_source = value_from(data, "DT_MAJ_GDUNO"),
    code_organisme = value_from(data, c("CD_ORGNS", "CD_ORGNS_RESP")),
    code_immeuble = value_from(data, "CD_IMM"),
    code_css = value_from(data, "CD_CS"),
    nom = coalesce(nom_organisme, nom_immeuble),
    nom_organisme = nom_organisme,
    nom_immeuble = nom_immeuble,
    municipalite = value_from(data, c("NOM_MUNCP", "NOM_MUNCP_GDUNO_IMM", "NOM_MUNCP_GDUNO_ORGNS")),
    mrc = value_from(data, "NOM_MRC"),
    region_administrative = value_from(data, "NOM_REG_ADM"),
    ordre_enseignement = value_from(data, c("ORDRE_ENS", "ORDRE_ENS_IMM")),
    reseau = value_from(data, "RESEAU"),
    type_organisme = value_from(data, "TYPE_ORGNS"),
    type_css = value_from(data, "TYPE_CS"),
    langue_enseignement = value_from(data, "LANG_ENS"),
    longitude = num_from(data, c("COORD_X_LL84_IMM", "COORD_X_LL84")),
    latitude = num_from(data, c("COORD_Y_LL84_IMM", "COORD_Y_LL84")),
    presence_prescolaire = value_from(data, "PRESC"),
    presence_primaire = value_from(data, "PRIM"),
    presence_secondaire = value_from(data, "SEC"),
    presence_formation_professionnelle = value_from(data, "FORM_PRO"),
    presence_education_adultes = value_from(data, "ADULTE"),
    site_web = value_from(data, c("SITE_WEB_ORGNS", "SITE_WEB")),
    telephone = value_from(data, "NO_TEL")
  )
}

etablissements <- pmap_dfr(
  resources |> select(raw_path, source_resource, resource_label, network_category, unit_kind),
  standardize_one
) |>
  mutate(
    has_coordinates = !is.na(longitude) & !is.na(latitude),
    has_region = !is.na(region_administrative) & region_administrative != ""
  ) |>
  arrange(source_resource, source_row)

resource_summary <- etablissements |>
  count(source_resource, resource_label, network_category, unit_kind, name = "n_lignes") |>
  left_join(resources |> select(source_resource, expected_rows), by = "source_resource") |>
  mutate(matches_expected_rows = n_lignes == expected_rows) |>
  arrange(source_resource)

stopifnot(
  nrow(etablissements) == 14067,
  n_distinct(etablissements$source_resource) == 9,
  all(resource_summary$matches_expected_rows),
  sum(etablissements$has_coordinates) == 14067,
  sum(etablissements$has_region) == 6220
)

write_csv(
  etablissements,
  file.path(processed_dir, "etablissements_enseignement_quebec.csv")
)

write_csv(
  resource_summary,
  file.path(processed_dir, "ressources_etablissements_enseignement.csv")
)

message("Source : ", source_page)
message("API CKAN : ", package_api)
message("Ressources CSV préparées : ", n_distinct(etablissements$source_resource))
message("Fichier préparé : ", file.path(processed_dir, "etablissements_enseignement_quebec.csv"))
