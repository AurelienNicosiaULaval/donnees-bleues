# Portrait des permis et de la forme bâtie par quartier
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

print(construction_quartiers |>
  arrange(desc(nombre_permis)) |>
  select(nom_quartier, nombre_permis, permis_par_km2, nombre_batiments, part_superficie_batie) |>
  slice_head(n = 10))

print(ggplot(
  construction_quartiers,
  aes(x = batiments_par_km2, y = permis_par_km2, label = nom_quartier)
) +
  geom_point(color = "#325EA8", size = 2.4, alpha = 0.8) +
  labs(
    x = "Bâtiments par km²",
    y = "Permis par km²",
    title = "Permis et densité de bâtiments par quartier"
  ) +
  theme_minimal())
