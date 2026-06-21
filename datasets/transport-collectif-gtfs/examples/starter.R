# Exemple de départ : GTFS du Réseau de transport de la Capitale

library(dplyr)
library(ggplot2)
library(readr)

# Télécharger et préparer le ZIP GTFS officiel.
source("datasets/transport-collectif-gtfs/preparation.R")

# Importer les tables préparées.
stops <- read_csv(
  "data/processed/transport-collectif-gtfs/arrets_gtfs_rtc.csv",
  show_col_types = FALSE
)

routes_summary <- read_csv(
  "data/processed/transport-collectif-gtfs/resume_parcours_gtfs_rtc.csv",
  show_col_types = FALSE
)

glimpse(stops)

ggplot(stops, aes(x = longitude, y = latitude)) +
  geom_point(alpha = 0.35, size = 0.7) +
  coord_equal() +
  labs(
    x = "Longitude",
    y = "Latitude",
    title = "Arrêts du RTC dans le flux GTFS",
    subtitle = "Carte d'arrêts, pas carte d'achalandage"
  )

routes_summary |>
  arrange(desc(n_trips)) |>
  select(route_short_name, route_description, n_trips, n_services) |>
  slice_head(n = 10)
