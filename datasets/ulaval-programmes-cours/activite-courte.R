# Lire les contrôles d’un manifeste institutionnel
# Ouvrir le projet RStudio de l’archive, puis exécuter ce script.
# Source : https://www.bqp.ulaval.ca/fichiers/ressources/gestion/codes-programmes-actifs.pdf
# Les données de classe sont figées; ce script ne les télécharge pas.

library(dplyr)
library(readr)


fichiers <- read_csv(
  "data/processed/ulaval-programmes-cours/resume_fichiers_ulaval.csv",
  show_col_types = FALSE
)

print(fichiers |>
  filter(phase == "core") |>
  select(
    dataset_id,
    expected_rows,
    observed_rows,
    row_count_matches,
    keys_unique,
    protected_fields_present
  ))
