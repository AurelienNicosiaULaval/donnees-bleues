# Documenter une intégration institutionnelle et ses droits
# Ouvrir le projet RStudio de l’archive, puis exécuter ce script.
# Source : https://www.bqp.ulaval.ca/fichiers/ressources/gestion/codes-programmes-actifs.pdf
# Les données de classe sont figées; ce script ne les télécharge pas.

library(dplyr)
library(readr)


resume <- read_csv(
  "data/processed/ulaval-programmes-cours/resume_ulaval_programmes_cours.csv",
  show_col_types = FALSE
)

fichiers <- read_csv(
  "data/processed/ulaval-programmes-cours/resume_fichiers_ulaval.csv",
  show_col_types = FALSE
)

droits <- read_csv(
  "data/processed/ulaval-programmes-cours/resume_droits_ulaval.csv",
  show_col_types = FALSE
)

print(resume |>
  select(source_found, validation_status, n_core_expected_rows, n_ges_expected_rows))

print(fichiers |>
  group_by(phase) |> summarise(lignes_observees = if (all(is.na(observed_rows))) NA_real_ else sum(observed_rows, na.rm = TRUE), .groups = "drop"))

print(droits)
