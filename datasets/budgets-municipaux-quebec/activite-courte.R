# Profils fonciers par classe de population
# Ouvrir le projet RStudio de l’archive, puis exécuter ce script.
# Source : https://www.donneesquebec.ca/recherche/dataset/profil-financier-des-municipalites-locales
# Les données de classe sont figées; ce script ne les télécharge pas.

# Load libraries
library(dplyr)
library(ggplot2)
library(readr)

# Import prepared data
municipalites <- read_csv(
  "data/processed/budgets-municipaux-quebec/profil_financier_municipalites_2025.csv",
  show_col_types = FALSE
)

dictionnaire <- read_csv(
  "data/processed/budgets-municipaux-quebec/dictionnaire_postes_profil_financier_2025.csv",
  show_col_types = FALSE
)

# Check the meaning of FIALX02005
print(dictionnaire |>
  filter(code_poste == "FIALX02005") |>
  select(code_poste, libelle_court, type_indicateur))

# Summarise by population class
resume_classes <- municipalites |>
  filter(!is.na(classe_population), !is.na(FIALX02005)) |>
  group_by(classe_population) |>
  summarise(
    municipalites = n(),
    population_totale = sum(population, na.rm = TRUE),
    part_residentielle_mediane = median(FIALX02005, na.rm = TRUE),
    part_residentielle_q1 = quantile(FIALX02005, 0.25, na.rm = TRUE),
    part_residentielle_q3 = quantile(FIALX02005, 0.75, na.rm = TRUE),
    .groups = "drop"
  )

print(resume_classes)

# Plot distribution by class
print(ggplot(
  municipalites |> filter(!is.na(classe_population), !is.na(FIALX02005)),
  aes(x = classe_population, y = FIALX02005)
) +
  geom_boxplot(fill = "#8FC7D9", color = "#1F3B57", outlier.alpha = 0.35) +
  coord_flip() +
  labs(
    x = "Classe de population",
    y = "Part résidentielle publiée",
    title = "Part résidentielle par classe de population",
    subtitle = "Profil financier 2024-2025, données de 2025"
  ))
