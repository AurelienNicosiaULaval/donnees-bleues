# Portrait spatial des prélèvements d'eau autorisés
# Ouvrir le projet RStudio de l’archive, puis exécuter ce script.
# Source : https://www.donneesquebec.ca/recherche/dataset/prelevements-eau
# Les données de classe sont figées; ce script ne les télécharge pas.

# Load libraries
library(dplyr)
library(ggplot2)
library(readr)

# Prepare official CSV

# Import prepared files
prelevements <- read_csv(
  "data/processed/prelevements-eau-autorises/prelevements_eau_autorises.csv",
  show_col_types = FALSE
)

resume_provenance <- read_csv(
  "data/processed/prelevements-eau-autorises/resume_provenance_prelevements_eau_autorises.csv",
  show_col_types = FALSE
)

principaux_sites <- read_csv(
  "data/processed/prelevements-eau-autorises/principaux_sites_prelevements_eau_autorises.csv",
  show_col_types = FALSE
)

valeurs_manquantes <- read_csv(
  "data/processed/prelevements-eau-autorises/valeurs_manquantes_prelevements_eau_autorises.csv",
  show_col_types = FALSE
)

# Key checks
print(prelevements |>
  summarise(
    sites = n(),
    documents = n_distinct(no_doc)
  ))

print(resume_provenance)
print(principaux_sites |> select(site_id, provenance_eau, volume_autorise_m3_j, nombre_sites_document, precision_volume) |> head(10))

print(ggplot(prelevements, aes(x = longitude, y = latitude, color = provenance_eau)) +
  geom_point(alpha = 0.55, size = 1.1) +
  coord_quickmap() +
  labs(
    x = "Longitude",
    y = "Latitude",
    color = "Provenance",
    title = "Sites de prélèvements d'eau autorisés",
    subtitle = "La carte montre des sites autorisés, pas les volumes réellement prélevés"
  ))
