# Portrait spatial des prélèvements d'eau autorisés
# Ouvrir le projet RStudio de l’archive, puis exécuter ce script.
# Source : https://www.donneesquebec.ca/recherche/dataset/prelevements-eau
# La copie de classe est figée; une copie API peut être sélectionnée avant l’activité.

# Load libraries
library(dplyr)
library(ggplot2)
library(readr)

# Prepare official CSV

# Import prepared files
prelevements <- read_csv(
  Sys.getenv("DB_PRELEVEMENTS_SNAPSHOT", unset = "data/processed/prelevements-eau-autorises/prelevements_eau_autorises.csv"),
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

# Les résumés sont recalculés à partir de la copie API choisie.
# Les noms des intervenants ne font pas partie de cette copie.
if (nzchar(Sys.getenv("DB_PRELEVEMENTS_SNAPSHOT"))) {
  resume_provenance <- prelevements |>
    group_by(provenance_eau) |>
    summarise(n_sites = n(), n_documents = n_distinct(no_doc),
      n_volume_manquant = sum(is.na(volume_autorise_l_j)),
      volume_median_m3_j = median(volume_autorise_m3_j, na.rm = TRUE),
      volume_max_m3_j = max(volume_autorise_m3_j, na.rm = TRUE), .groups = "drop") |>
    arrange(desc(n_sites))
  principaux_sites <- prelevements |>
    filter(!is.na(volume_autorise_l_j)) |>
    arrange(desc(volume_autorise_l_j)) |>
    slice_head(n = 20)
}

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
