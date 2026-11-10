# Volumes autorisés par provenance de l'eau
# Ouvrir le projet RStudio de l’archive, puis exécuter ce script.
# Source : https://www.donneesquebec.ca/recherche/dataset/prelevements-eau
# La copie de classe est figée; une copie API peut être sélectionnée avant l’activité.

# Load libraries
library(dplyr)
library(ggplot2)
library(readr)

# Prepare official CSV

# Import prepared data
prelevements <- read_csv(
  Sys.getenv("DB_PRELEVEMENTS_SNAPSHOT", unset = "data/processed/prelevements-eau-autorises/prelevements_eau_autorises.csv"),
  show_col_types = FALSE
)

# Aggregate by provenance
resume_provenance <- prelevements |>
  group_by(provenance_eau) |>
  summarise(
    sites = n(),
    volume_median_m3_j = median(volume_autorise_m3_j, na.rm = TRUE),
    .groups = "drop"
  ) |>
  arrange(desc(volume_median_m3_j))

print(resume_provenance)

# Plot authorized volumes
print(ggplot(resume_provenance, aes(x = reorder(provenance_eau, volume_median_m3_j), y = volume_median_m3_j)) +
  geom_col(fill = "#325EA8") +
  coord_flip() +
  labs(
    x = "Provenance de l'eau",
    y = "Médiane des plafonds inscrits par site (m³/j)",
    title = "Volumes autorisés par provenance de l'eau",
    subtitle = "Plafonds par site; les conditions communes empêchent leur addition en un total"
  ))
