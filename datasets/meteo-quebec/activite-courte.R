# Variabilité saisonnière de la température à Québec
# Ouvrir le projet RStudio de l’archive, puis exécuter ce script.
# Source : https://climate.weather.gc.ca/historical_data/search_historic_data_e.html
# Les données de classe sont figées; ce script ne les télécharge pas.

# Load libraries
library(dplyr)
library(ggplot2)
library(readr)

# Prepare data

# Import prepared data
meteo <- read_csv(
  "data/processed/meteo-quebec/meteo_quebec.csv",
  show_col_types = FALSE
)

# Check structure
print(meteo |>
  summarise(
    lignes = n(),
    premiere_date = min(date),
    derniere_date = max(date)
  ))

# Missing values for temperature variables
print(meteo |>
  summarise(
    max_temp_manquant = sum(is.na(max_temp)),
    mean_temp_manquant = sum(is.na(mean_temp)),
    min_temp_manquant = sum(is.na(min_temp))
  ))

# Seasonal summary
resume_saison <- meteo |>
  group_by(saison) |>
  summarise(
    n = n(),
    moyenne = mean(mean_temp, na.rm = TRUE),
    ecart_type = sd(mean_temp, na.rm = TRUE),
    .groups = "drop"
  ) |>
  arrange(desc(ecart_type))

print(resume_saison)

# Seasonal distribution
print(ggplot(meteo |> filter(is.finite(mean_temp)), aes(x = saison, y = mean_temp)) +
  geom_boxplot(outlier.alpha = 0.25) +
  labs(
    x = "Saison",
    y = "Température moyenne quotidienne (°C)",
    title = "Variabilité saisonnière de la température à Québec"
  ))
