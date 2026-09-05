# Comparer les permis par quartier
# Ouvrir le projet RStudio de l’archive, puis exécuter ce script.
# Source : https://www.donneesquebec.ca/recherche/dataset/permis-delivres-ville-de-quebec
# Les données de classe sont figées; ce script ne les télécharge pas.

library(dplyr)
library(ggplot2)
library(readr)

construction_quartiers <- read_csv(
  "data/processed/construction-quartiers-quebec/quebec_construction_quartiers.csv",
  show_col_types = FALSE
)

top_quartiers <- construction_quartiers |>
  arrange(desc(permis_par_km2)) |>
  slice_head(n = 10)

print(ggplot(top_quartiers, aes(x = reorder(nom_quartier, permis_par_km2), y = permis_par_km2)) +
  geom_col(fill = "#325EA8") +
  coord_flip() +
  labs(
    x = "Quartier",
    y = "Permis par km²",
    title = "Densité de permis délivrés par quartier"
  ) +
  theme_minimal())
