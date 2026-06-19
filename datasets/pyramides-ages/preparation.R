# Préparer les estimations de population pour les pyramides des âges.

library(cansim)
library(dplyr)
library(readr)

dir.create("data/raw/pyramides-ages", recursive = TRUE, showWarnings = FALSE)
dir.create("data/processed/pyramides-ages", recursive = TRUE, showWarnings = FALSE)

raw_path <- "data/raw/pyramides-ages/statcan_17-10-0005-01.csv"
processed_path <- "data/processed/pyramides-ages/population_pyramides_quebec_canada_latest.csv"

population_raw <- get_cansim("17-10-0005-01")

write_csv(population_raw, raw_path)

age_groups <- c(
  paste(seq(0, 95, by = 5), "to", seq(4, 99, by = 5), "years"),
  "100 years and older"
)

latest_year <- max(as.integer(population_raw$REF_DATE), na.rm = TRUE)

population_pyramides <- population_raw |>
  filter(
    GEO %in% c("Canada", "Quebec"),
    as.integer(REF_DATE) == latest_year,
    Gender %in% c("Men+", "Women+"),
    `Age group` %in% age_groups,
    UOM == "Persons"
  ) |>
  transmute(
    year = as.integer(REF_DATE),
    geography = as.character(GEO),
    gender = as.character(Gender),
    age_group = factor(as.character(`Age group`), levels = age_groups),
    population = VALUE,
    population_plot = if_else(gender == "Men+", -population, population)
  ) |>
  group_by(year, geography) |>
  mutate(
    proportion = population / sum(population, na.rm = TRUE),
    proportion_plot = if_else(gender == "Men+", -proportion, proportion)
  ) |>
  ungroup()

write_csv(population_pyramides, processed_path)

message("Fichier brut : ", raw_path)
message("Fichier préparé : ", processed_path)
