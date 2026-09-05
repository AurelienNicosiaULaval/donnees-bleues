source("R/utils_downloads.R")
# Préparation : Géobase du réseau hydrographique du Québec
# Source officielle : Données Québec, paquet CKAN bfbdeb1d-8398-444b-ad78-ab81f9d14e60.
#
# Le référentiel complet est volumineux. Cette préparation conserve donc les
# métadonnées du paquet et l'index CSV officiel de téléchargement, sans
# télécharger les géodatabases détaillées.

library(dplyr)
library(jsonlite)
library(readr)
library(stringr)

raw_dir <- "data/raw/grhq"
processed_dir <- "data/processed/grhq"
dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(processed_dir, recursive = TRUE, showWarnings = FALSE)

access_date <- as.character(Sys.Date())
source_page <- "https://www.donneesquebec.ca/recherche/dataset/grhq"
package_api <- "https://www.donneesquebec.ca/recherche/api/3/action/package_show?id=grhq"
index_url <- "https://diffusion.mern.gouv.qc.ca/Diffusion/RGQ/Documentation/GRHQ/Index_GRHQ.csv"

package_json_path <- file.path(raw_dir, "package_show_grhq.json")
index_raw_path <- file.path(raw_dir, "Index_GRHQ.csv")

download_source(package_api, package_json_path, mode = "wb", quiet = TRUE)
download_source(index_url, index_raw_path, mode = "wb", quiet = TRUE)

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
    last_modified = as.character(last_modified)
  )

grhq_index <- read_csv(
  index_raw_path,
  show_col_types = FALSE,
  locale = locale(encoding = "UTF-8")
) |>
  rename(
    bloc = Bloc,
    zone = Zone,
    fgdb_url = FGDB
  ) |>
  mutate(
    bloc = as.character(bloc),
    region_hydrographique = str_extract(bloc, "^[0-9]+"),
    partie = str_extract(bloc, "(?<=_)[0-9]+"),
    partie = as.integer(partie),
    is_split_unit = !is.na(partie),
    unit_kind = if_else(
      is_split_unit,
      "Partie de région hydrographique",
      "Région hydrographique complète"
    ),
    fgdb_zip_file = basename(fgdb_url),
    fgdb_directory = dirname(fgdb_url),
    source_index_url = index_url,
    access_date = access_date
  ) |>
  select(
    bloc,
    region_hydrographique,
    partie,
    is_split_unit,
    unit_kind,
    zone,
    fgdb_zip_file,
    fgdb_directory,
    fgdb_url,
    source_index_url,
    access_date
  )

resource_summary <- resources |>
  count(format, name = "n_resources") |>
  arrange(desc(n_resources), format)

stopifnot(
  nrow(resources) == 9,
  nrow(grhq_index) == 16,
  n_distinct(grhq_index$region_hydrographique) == 12,
  sum(grhq_index$is_split_unit) == 7,
  all(!is.na(grhq_index$fgdb_url)),
  any(resources$resource_name == "Index de téléchargement (format csv)"),
  any(resources$resource_name == "Guide de l'utilisateur"),
  any(resources$format == "WMS")
)

write_csv(
  grhq_index,
  file.path(processed_dir, "grhq_index_telechargement.csv")
)

write_csv(
  resources,
  file.path(processed_dir, "ressources_grhq.csv")
)

write_csv(
  resource_summary,
  file.path(processed_dir, "resume_formats_grhq.csv")
)

message("Source : ", source_page)
message("API CKAN : ", package_api)
message("Index préparé : ", file.path(processed_dir, "grhq_index_telechargement.csv"))
message("Unités de téléchargement : ", nrow(grhq_index))
message("Ressources CKAN documentées : ", nrow(resources))

record_preparation("grhq")
