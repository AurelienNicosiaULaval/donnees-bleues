source("R/utils_downloads.R")
# Préparation : Registre des prélèvements d'eau autorisés
# Source officielle : Données Québec, paquet CKAN d9564fe0-6d50-4f89-b12e-47a461e1f68e.

library(dplyr)
library(jsonlite)
library(readr)
library(tidyr)

raw_dir <- "data/raw/prelevements-eau-autorises"
processed_dir <- "data/processed/prelevements-eau-autorises"
dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(processed_dir, recursive = TRUE, showWarnings = FALSE)

access_date <- as.character(Sys.Date())
source_page <- "https://www.donneesquebec.ca/recherche/dataset/prelevements-eau"
package_api <- "https://www.donneesquebec.ca/recherche/api/3/action/package_show?id=prelevements-eau"
csv_url <- "https://www.donneesquebec.ca/recherche/dataset/d9564fe0-6d50-4f89-b12e-47a461e1f68e/resource/5c090292-a681-4413-9399-f17bcdf62753/download/prelevement_autorise_20250915.csv"
metadata_pdf_url <- "https://www.donneesquebec.ca/recherche/dataset/d9564fe0-6d50-4f89-b12e-47a461e1f68e/resource/24b357f1-fd58-44a7-8cd3-7098645ae907/download/md_prelevementseauautorises.pdf"

package_json_path <- file.path(raw_dir, "package_show_prelevements_eau_autorises.json")
csv_raw_path <- file.path(raw_dir, "prelevement_autorise_20250915.csv")
metadata_pdf_path <- file.path(raw_dir, "md_prelevementseauautorises.pdf")

download_source(package_api, package_json_path, mode = "wb", quiet = TRUE)
download_source(csv_url, csv_raw_path, mode = "wb", quiet = TRUE)
download_source(metadata_pdf_url, metadata_pdf_path, mode = "wb", quiet = TRUE)

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
    last_modified = as.character(last_modified),
    size = suppressWarnings(as.numeric(size))
  )

source_data <- read_csv(csv_raw_path, show_col_types = FALSE)

prelevements <- source_data |>
  transmute(
    no_doc = as.character(no_doc),
    site_id = as.character(Id),
    nombre_sites_document = as.integer(count_doc),
    nom_intervenant = int_nom,
    volume_autorise_l_j = parse_number(as.character(vol_aut)),
    volume_autorise_m3_j = volume_autorise_l_j / 1000,
    precision_volume = vol_prec,
    provenance_eau = eau_prov,
    longitude = as.numeric(long),
    latitude = as.numeric(lat),
    has_volume = !is.na(volume_autorise_l_j),
    has_precision_volume = !is.na(precision_volume) & precision_volume != "",
    has_coordinates = !is.na(longitude) & !is.na(latitude),
    source_csv_url = csv_url,
    source_version = "2025-09-15",
    access_date = access_date
  ) |>
  arrange(desc(volume_autorise_l_j), no_doc, site_id)

missing_summary <- prelevements |>
  summarise(across(everything(), ~ sum(is.na(.x)))) |>
  pivot_longer(
    cols = everything(),
    names_to = "variable",
    values_to = "n_missing"
  ) |>
  mutate(
    n_rows = nrow(prelevements),
    pct_missing = round(100 * n_missing / n_rows, 2)
  ) |>
  arrange(desc(n_missing), variable)

# Les plafonds de plusieurs sites peuvent être soumis à une limite commune.
# Ne pas calculer de volume total autorisé en sommant les lignes du registre.
summary_by_provenance <- prelevements |>
  group_by(provenance_eau) |>
  summarise(
    n_sites = n(),
    n_documents = n_distinct(no_doc),
    n_intervenants = n_distinct(nom_intervenant),
    n_volume_manquant = sum(is.na(volume_autorise_l_j)),
    volume_median_m3_j = median(volume_autorise_m3_j, na.rm = TRUE),
    volume_max_m3_j = max(volume_autorise_m3_j, na.rm = TRUE),
    .groups = "drop"
  ) |>
  arrange(desc(n_sites))

top_sites <- prelevements |>
  filter(!is.na(volume_autorise_l_j)) |>
  arrange(desc(volume_autorise_l_j)) |>
  slice_head(n = 20) |>
  select(
    no_doc,
    site_id,
    nom_intervenant,
    provenance_eau,
    nombre_sites_document,
    precision_volume,
    volume_autorise_l_j,
    volume_autorise_m3_j,
    longitude,
    latitude
  )

top_intervenants <- prelevements |>
  group_by(nom_intervenant) |>
  summarise(
    n_sites = n(),
    n_documents = n_distinct(no_doc),
    .groups = "drop"
  ) |>
  arrange(desc(n_sites)) |>
  slice_head(n = 20)

dataset_summary <- tibble::tibble(
  metric = c(
    "source_page",
    "package_api",
    "csv_url",
    "metadata_pdf_url",
    "access_date",
    "source_version",
    "n_rows",
    "n_columns_source",
    "n_columns_prepared",
    "n_resources_ckan",
    "n_documents",
    "n_intervenants",
    "n_sites_with_coordinates",
    "n_missing_volume",
    "n_with_precision_volume",
    "volume_median_l_j",
    "volume_max_l_j"
  ),
  value = c(
    source_page,
    package_api,
    csv_url,
    metadata_pdf_url,
    access_date,
    "2025-09-15",
    as.character(nrow(prelevements)),
    as.character(ncol(source_data)),
    as.character(ncol(prelevements)),
    as.character(nrow(resources)),
    as.character(n_distinct(prelevements$no_doc)),
    as.character(n_distinct(prelevements$nom_intervenant)),
    as.character(sum(prelevements$has_coordinates)),
    as.character(sum(is.na(prelevements$volume_autorise_l_j))),
    as.character(sum(prelevements$has_precision_volume)),
    as.character(median(prelevements$volume_autorise_l_j, na.rm = TRUE)),
    as.character(max(prelevements$volume_autorise_l_j, na.rm = TRUE))
  )
)

stopifnot(
  nrow(resources) >= 10,
  nrow(prelevements) == 1777,
  ncol(source_data) == 9,
  ncol(prelevements) == 16,
  n_distinct(prelevements$no_doc) == 1021,
  n_distinct(prelevements$nom_intervenant) == 827,
  sum(prelevements$has_coordinates) == 1777,
  sum(is.na(prelevements$volume_autorise_l_j)) == 19,
  sum(prelevements$has_precision_volume) == 130,
  setequal(prelevements$provenance_eau, c("Souterraine", "Surface", "Activités de dénoyage")),
  max(prelevements$volume_autorise_l_j, na.rm = TRUE) == 499000000
)

write_csv(
  prelevements,
  file.path(processed_dir, "prelevements_eau_autorises.csv")
)

write_csv(
  resources,
  file.path(processed_dir, "ressources_prelevements_eau_autorises.csv")
)

write_csv(
  missing_summary,
  file.path(processed_dir, "valeurs_manquantes_prelevements_eau_autorises.csv")
)

write_csv(
  summary_by_provenance,
  file.path(processed_dir, "resume_provenance_prelevements_eau_autorises.csv")
)

write_csv(
  top_sites,
  file.path(processed_dir, "principaux_sites_prelevements_eau_autorises.csv")
)

write_csv(
  top_intervenants,
  file.path(processed_dir, "principaux_intervenants_prelevements_eau_autorises.csv")
)

write_csv(
  dataset_summary,
  file.path(processed_dir, "resume_prelevements_eau_autorises.csv")
)

message("Source : ", source_page)
message("API CKAN : ", package_api)
message("Fichier préparé : ", file.path(processed_dir, "prelevements_eau_autorises.csv"))
message("Sites préparés : ", nrow(prelevements))
message("Ressources CKAN documentées : ", nrow(resources))

record_preparation("prelevements-eau-autorises")
