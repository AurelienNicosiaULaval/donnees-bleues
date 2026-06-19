# Préparer le suivi physicochimique et bactériologique des rivières et du fleuve.

library(dplyr)
library(readr)

dir.create("data/raw/suivi-rivieres-fleuve", recursive = TRUE, showWarnings = FALSE)
dir.create("data/processed/suivi-rivieres-fleuve", recursive = TRUE, showWarnings = FALSE)

source_url <- "https://stqc380donopppdtce01.blob.core.windows.net/donnees-ouvertes/IQBP/DQ/IQBP_csv.zip"
zip_path <- "data/raw/suivi-rivieres-fleuve/IQBP_csv.zip"
extract_dir <- "data/raw/suivi-rivieres-fleuve/IQBP_csv"

download.file(source_url, zip_path, mode = "wb", quiet = TRUE)

if (dir.exists(extract_dir)) {
  unlink(extract_dir, recursive = TRUE)
}
dir.create(extract_dir, recursive = TRUE, showWarnings = FALSE)
unzip(zip_path, exdir = extract_dir)

stations <- read_delim(
  file.path(extract_dir, "stations_p.csv"),
  delim = ";",
  show_col_types = FALSE
) |>
  rename_with(tolower) |>
  transmute(
    no_bqma,
    hydronyme,
    description,
    type_station,
    type_suivi,
    annee,
    n_echant,
    iqbp_med,
    ptot_med_mgl,
    ntot_med_mgl,
    nox_med_mgl,
    chla_med_ugl,
    cf_med_ufc,
    latitude,
    longitude,
    bv_n1m,
    bv_n2m,
    zgiebv,
    zgiesl
  )

aires_drainage <- read_delim(
  file.path(extract_dir, "ad_s.csv"),
  delim = ";",
  show_col_types = FALSE
) |>
  rename_with(tolower) |>
  transmute(
    no_bqma,
    superf_qc_km2,
    superf_tot_km2,
    frontiere,
    pc_foret,
    pc_agricole,
    pc_anthropique,
    pc_aquatique,
    pc_humide,
    pc_coupe_regen,
    pc_sol_nu,
    pc_non_classe,
    annee_utilisation_territoire = annee_ut
  )

stations_aires <- stations |>
  left_join(aires_drainage, by = "no_bqma")

write_csv(stations, "data/processed/suivi-rivieres-fleuve/stations_qualite_eau.csv")
write_csv(aires_drainage, "data/processed/suivi-rivieres-fleuve/aires_drainage.csv")
write_csv(stations_aires, "data/processed/suivi-rivieres-fleuve/stations_qualite_eau_aires.csv")

message("Fichier brut : ", zip_path)
message("Fichiers préparés dans data/processed/suivi-rivieres-fleuve/")
