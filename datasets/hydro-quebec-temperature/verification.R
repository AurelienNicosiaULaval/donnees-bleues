# Vérifier la version référencée sans modifier les fichiers du contributeur.
# Depuis la racine du dépôt :
# Rscript datasets/hydro-quebec-temperature/verification.R [chemin-du-CSV]
library(readr)
library(dplyr)
library(yaml)
library(digest)

metadata <- read_yaml("datasets/hydro-quebec-temperature/metadata.yml")
arguments <- commandArgs(trailingOnly = TRUE)
input <- if (length(arguments)) arguments[[1L]] else tempfile(fileext = ".csv")
if (!length(arguments)) download.file(metadata$download_url, input, mode = "wb", quiet = TRUE)
stopifnot(digest(file = input, algo = "sha256") == metadata$verification$sha256)

hydro <- read_csv(input, na = "", show_col_types = FALSE)
hours <- hydro$heure_fin_utc
summary <- hydro |>
  summarise(
    rows = n(), columns = ncol(hydro),
    demand_present = sum(!is.na(demande_mw)),
    temperature_present = sum(!is.na(temp_ponderee)),
    complete_pairs = sum(!is.na(demande_mw) & !is.na(temp_ponderee)),
    recent_hours = sum(source_demande == "temps_reel", na.rm = TRUE),
    partial_recent_hours = sum(source_demande == "temps_reel" & n_obs_15min < 4, na.rm = TRUE)
  )
expected <- metadata$verification
for (field in c("rows", "columns", "demand_present", "temperature_present", "complete_pairs")) {
  stopifnot(summary[[field]] == expected[[field]])
}
stopifnot(!anyNA(hours), !anyDuplicated(hours), all(as.numeric(diff(hours), units = "secs") == 3600),
          summary$recent_hours == 62L, summary$partial_recent_hours == 1L,
          all(is.na(hydro$demande_mw[hydro$annee == 2025])))
print(summary, width = Inf)
print(hydro |> group_by(annee) |> summarise(
  hours = n(), demand_present = sum(!is.na(demande_mw)),
  temperature_present = sum(!is.na(temp_ponderee)), .groups = "drop"))
message("Empreinte, dimensions, couverture horaire et valeurs manquantes vérifiées.")
