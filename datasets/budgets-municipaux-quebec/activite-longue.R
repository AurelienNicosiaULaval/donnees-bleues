# Portrait descriptif des profils financiers municipaux
# Ouvrir le projet RStudio de l’archive, puis exécuter ce script.
# Source : https://www.donneesquebec.ca/recherche/dataset/profil-financier-des-municipalites-locales
# Les données de classe sont figées; ce script ne les télécharge pas.

# Load libraries
library(dplyr)
library(ggplot2)
library(readr)
library(stringr)

# Import prepared files
municipalites <- read_csv(
  "data/processed/budgets-municipaux-quebec/profil_financier_municipalites_2025.csv",
  show_col_types = FALSE
)

profil_long <- read_csv(
  "data/processed/budgets-municipaux-quebec/profil_financier_municipalites_long_2025.csv",
  show_col_types = FALSE
)

dictionnaire <- read_csv(
  "data/processed/budgets-municipaux-quebec/dictionnaire_postes_profil_financier_2025.csv",
  show_col_types = FALSE
)

valeurs_manquantes <- read_csv(
  "data/processed/budgets-municipaux-quebec/valeurs_manquantes_profil_financier_2025.csv",
  show_col_types = FALSE
)

# Choose a small set of interpretable indicators
indicateurs_retenus <- c(
  "FIALX02005",
  "FIALX02006",
  "FIALX02007",
  "FIALX02010",
  "FIALX02097"
)

profil_selection <- profil_long |>
  filter(code_poste %in% indicateurs_retenus, !is.na(valeur)) |>
  left_join(
    dictionnaire |> select(code_poste, libelle_court, type_indicateur),
    by = c("code_poste", "libelle_court", "type_indicateur")
  )

# Summary by region and indicator
resume_regions <- profil_selection |>
  filter(!is.na(region_administrative)) |>
  group_by(region_administrative, code_poste, libelle_court) |>
  summarise(
    municipalites = n(),
    mediane = median(valeur, na.rm = TRUE),
    q1 = quantile(valeur, 0.25, na.rm = TRUE),
    q3 = quantile(valeur, 0.75, na.rm = TRUE),
    .groups = "drop"
  )

print(resume_regions)

# Visualise one selected indicator
print(ggplot(
  profil_selection |>
    filter(code_poste == "FIALX02097", !is.na(classe_population)),
  aes(x = classe_population, y = valeur)
) +
  geom_boxplot(fill = "#D8B365", color = "#4A3A1D", outlier.alpha = 0.35) +
  coord_flip() +
  labs(
    x = "Classe de population",
    y = "Indice RFU publié",
    title = "Indice RFU par classe de population",
    subtitle = "Profil financier 2024-2025, données de 2025"
  ))
