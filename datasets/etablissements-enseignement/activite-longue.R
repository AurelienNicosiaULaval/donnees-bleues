# Portrait territorial prudent des établissements d'enseignement
# Ouvrir le projet RStudio de l’archive, puis exécuter ce script.
# Source : https://www.donneesquebec.ca/recherche/dataset/localisation-des-etablissements-d-enseignement-du-reseau-scolaire-au-quebec
# Les données de classe sont figées; ce script ne les télécharge pas.

# Load libraries
library(dplyr)
library(ggplot2)
library(readr)

# Prepare official files

# Import prepared data
etablissements <- read_csv(
  "data/processed/etablissements-enseignement/etablissements_enseignement_quebec.csv",
  show_col_types = FALSE
)

# Global structure
structure_ressources <- etablissements |>
  count(source_resource, resource_label, network_category, unit_kind, sort = TRUE)

print(structure_ressources)

# Missing region by resource
regions_manquantes <- etablissements |>
  count(source_resource, resource_label, has_region) |>
  group_by(source_resource, resource_label) |>
  mutate(proportion = n / sum(n)) |>
  ungroup()

print(regions_manquantes)

# Example: regional portrait among rows with a known region
portrait_regional <- etablissements |>
  filter(has_region) |>
  count(region_administrative, network_category, sort = TRUE)

print(portrait_regional)

# Example map for one region
region_choisie <- "Montréal"

donnees_region <- etablissements |>
  filter(has_region, region_administrative == region_choisie)

print(ggplot(donnees_region, aes(x = longitude, y = latitude, color = network_category)) +
  geom_point(alpha = 0.6, size = 1) +
  coord_quickmap() +
  labs(
    x = "Longitude",
    y = "Latitude",
    color = "Catégorie",
    title = paste("Lignes géolocalisées dans la région :", region_choisie),
    subtitle = "Les points proviennent de plusieurs ressources; l'unité statistique varie"
  ))
