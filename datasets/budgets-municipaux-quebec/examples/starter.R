# Exemple de départ : Profil financier des municipalités locales du Québec

library(dplyr)
library(ggplot2)
library(readr)

# Préparer les fichiers officiels depuis la racine du projet.
source("datasets/budgets-municipaux-quebec/preparation.R")

municipalites <- read_csv(
  "data/processed/budgets-municipaux-quebec/profil_financier_municipalites_2025.csv",
  show_col_types = FALSE
)

dictionnaire <- read_csv(
  "data/processed/budgets-municipaux-quebec/dictionnaire_postes_profil_financier_2025.csv",
  show_col_types = FALSE
)

glimpse(municipalites)

dictionnaire |>
  filter(code_poste %in% c("FIALX02005", "FIALX02006", "FIALX02097")) |>
  select(code_poste, libelle_court, type_indicateur)

resume_classes <- municipalites |>
  filter(!is.na(classe_population), !is.na(FIALX02005)) |>
  group_by(classe_population) |>
  summarise(
    municipalites = n(),
    population_totale = sum(population, na.rm = TRUE),
    part_residentielle_mediane = median(FIALX02005, na.rm = TRUE),
    .groups = "drop"
  )

resume_classes

ggplot(
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
  )
