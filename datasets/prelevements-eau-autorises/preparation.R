# Préparer le registre des prélèvements d'eau autorisés.

library(dplyr)
library(readr)

dir.create("data/raw/prelevements-eau-autorises", recursive = TRUE, showWarnings = FALSE)
dir.create("data/processed/prelevements-eau-autorises", recursive = TRUE, showWarnings = FALSE)

source_url <- "https://www.donneesquebec.ca/recherche/dataset/d9564fe0-6d50-4f89-b12e-47a461e1f68e/resource/5c090292-a681-4413-9399-f17bcdf62753/download/prelevement_autorise_20250915.csv"
raw_path <- "data/raw/prelevements-eau-autorises/prelevement_autorise_20250915.csv"
processed_path <- "data/processed/prelevements-eau-autorises/prelevements_eau_autorises.csv"

download.file(source_url, raw_path, mode = "wb", quiet = TRUE)

prelevements <- read_csv(raw_path, show_col_types = FALSE) |>
  transmute(
    no_doc = as.character(no_doc),
    site_id = Id,
    nombre_sites_document = count_doc,
    nom_intervenant = int_nom,
    volume_autorise_l_j = parse_number(as.character(vol_aut)),
    volume_autorise_m3_j = volume_autorise_l_j / 1000,
    precision_volume = vol_prec,
    provenance_eau = eau_prov,
    longitude = as.numeric(long),
    latitude = as.numeric(lat)
  )

write_csv(prelevements, processed_path)

message("Fichier brut : ", raw_path)
message("Fichier préparé : ", processed_path)
