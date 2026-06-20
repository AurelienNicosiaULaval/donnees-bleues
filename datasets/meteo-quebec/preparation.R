# Préparation : Météo quotidienne à Québec
# Source pédagogique : UlavalSSD::MeteoQuebec
# Source primaire documentée : Environnement et Changement climatique Canada via weathercan

library(dplyr)
library(lubridate)
library(readr)
library(UlavalSSD)

dir.create("data_processed", showWarnings = FALSE)

meteo_quebec <- MeteoQuebec |>
  mutate(
    date = make_date(year, as.integer(month), as.integer(day)),
    mois = month(date, label = TRUE, abbr = FALSE),
    annee = year
  ) |>
  select(
    date,
    annee,
    mois,
    max_temp,
    mean_temp,
    min_temp,
    total_precip,
    total_rain,
    total_snow,
    snow_grnd
  )

write_csv(meteo_quebec, "data_processed/meteo_quebec.csv")

