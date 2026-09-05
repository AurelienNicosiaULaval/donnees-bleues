# Portrait descriptif de la météo quotidienne à Québec
# Ouvrir le projet RStudio de l’archive, puis exécuter ce script.
# Source : https://climate.weather.gc.ca/historical_data/search_historic_data_e.html
# Les données de classe sont figées; ce script ne les télécharge pas.

# Load libraries
library(dplyr)
library(ggplot2)
library(readr)

# Prepare data

# Import prepared files
meteo <- read_csv(
  "data/processed/meteo-quebec/meteo_quebec.csv",
  show_col_types = FALSE
)

valeurs_manquantes <- read_csv(
  "data/processed/meteo-quebec/valeurs_manquantes_meteo_quebec.csv",
  show_col_types = FALSE
)

resume_saisons <- read_csv(
  "data/processed/meteo-quebec/resume_saisons_meteo_quebec.csv",
  show_col_types = FALSE
)

# Key checks
print(meteo |>
  summarise(
    lignes = n(),
    premiere_date = min(date),
    derniere_date = max(date),
    moyenne_temperature = mean(mean_temp, na.rm = TRUE),
    moyenne_precipitation = mean(total_precip, na.rm = TRUE)
  ))

print(valeurs_manquantes |>
  filter(n_missing > 0) |>
  arrange(desc(n_missing)))

# Temperature since 2020
print(meteo |>
  filter(annee >= 2020) |>
  ggplot(aes(x = date, y = mean_temp)) +
  geom_line(alpha = 0.7, linewidth = 0.3) +
  labs(
    x = "Date",
    y = "Température moyenne quotidienne (°C)",
    title = "Température quotidienne moyenne à Québec depuis 2020"
  ))

# Les jours sans mesure sont exclus du graphique, pas assimilés à zéro.
print(meteo |> summarise(jours = n(), precipitation_absente = sum(is.na(total_precip))))

# Seasonal precipitation distribution
print(ggplot(meteo |> filter(is.finite(total_precip)), aes(x = saison, y = total_precip)) +
  geom_boxplot(outlier.alpha = 0.25) +
  coord_cartesian(ylim = c(0, 30)) +
  labs(
    x = "Saison",
    y = "Précipitations totales quotidiennes (mm)",
    title = "Distribution saisonnière des précipitations quotidiennes",
    subtitle = "Zoom de 0 à 30 mm; les valeurs supérieures restent incluses dans les quartiles"
  ))
