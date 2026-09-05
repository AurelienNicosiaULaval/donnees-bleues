source("R/utils_downloads.R")
# Préparation : Pyramides des âges au Canada et au Québec
# Source officielle : Statistique Canada, tableau 17-10-0005-01.

library(cansim)
library(dplyr)
library(readr)
library(tidyr)

raw_dir <- "data/raw/pyramides-ages"
processed_dir <- "data/processed/pyramides-ages"
dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(processed_dir, recursive = TRUE, showWarnings = FALSE)

access_date <- as.character(Sys.Date())
table_id <- "17-10-0005-01"
source_page <- "https://www150.statcan.gc.ca/t1/tbl1/fr/tv.action?pid=1710000501"
catalogue_page <- "https://www150.statcan.gc.ca/n1/fr/catalogue/1710000501"
doi_url <- "https://doi.org/10.25318/1710000501-fra"

raw_path <- file.path(raw_dir, "statcan_17-10-0005-01.csv")
latest_path <- file.path(processed_dir, "population_pyramides_quebec_canada_latest.csv")
comparison_path <- file.path(processed_dir, "population_pyramides_quebec_canada_2001_2025.csv")
indicators_path <- file.path(processed_dir, "indicateurs_age_quebec_canada_2025.csv")
age_gender_path <- file.path(processed_dir, "resume_groupes_age_genre_2025.csv")
summary_path <- file.path(processed_dir, "resume_pyramides_ages.csv")

age_groups <- c(
  paste(seq(0, 95, by = 5), "to", seq(4, 99, by = 5), "years"),
  "100 years and older"
)

age_groups_0_14 <- age_groups[1:3]
age_groups_15_64 <- age_groups[4:13]
age_groups_65_plus <- age_groups[14:21]

if (identical(Sys.getenv("DB_OFFLINE"), "true")) {
  download_source(source_page, raw_path)
  population_raw <- read_csv(raw_path, show_col_types = FALSE)
} else {
  population_raw <- get_cansim(table_id, refresh = TRUE)
  write_csv(population_raw, raw_path)
  record_source(raw_path, source_page, kind = "cansim_export",
                details = list(package = "cansim", version = as.character(packageVersion("cansim")), table_id = table_id))
}

required_columns <- c("REF_DATE", "GEO", "Gender", "Age group", "VALUE", "UOM")
missing_columns <- setdiff(required_columns, names(population_raw))
if (length(missing_columns) > 0L) {
  stop(
    "Colonnes StatCan manquantes : ",
    paste(missing_columns, collapse = ", "),
    call. = FALSE
  )
}

latest_year <- max(as.integer(population_raw$REF_DATE), na.rm = TRUE)
comparison_years <- c(2001L, latest_year)

population_clean <- population_raw |>
  transmute(
    year = as.integer(REF_DATE),
    geography = as.character(GEO),
    gender = as.character(Gender),
    age_group = as.character(`Age group`),
    value = as.numeric(VALUE),
    unit = as.character(UOM)
  )

population_pyramides <- population_clean |>
  filter(
    geography %in% c("Canada", "Quebec"),
    year == latest_year,
    gender %in% c("Men+", "Women+"),
    age_group %in% age_groups,
    unit == "Persons"
  ) |>
  transmute(
    year,
    geography,
    gender,
    age_group = factor(age_group, levels = age_groups),
    population = value,
    population_plot = if_else(gender == "Men+", -population, population)
  ) |>
  group_by(year, geography) |>
  mutate(
    proportion = population / sum(population, na.rm = TRUE),
    proportion_plot = if_else(gender == "Men+", -proportion, proportion)
  ) |>
  ungroup() |>
  arrange(geography, gender, age_group)

population_comparison <- population_clean |>
  filter(
    geography %in% c("Canada", "Quebec"),
    year %in% comparison_years,
    gender %in% c("Men+", "Women+"),
    age_group %in% age_groups,
    unit == "Persons"
  ) |>
  transmute(
    year,
    geography,
    gender,
    age_group = factor(age_group, levels = age_groups),
    population = value
  ) |>
  group_by(year, geography) |>
  mutate(proportion = population / sum(population, na.rm = TRUE)) |>
  ungroup() |>
  arrange(year, geography, gender, age_group)

total_by_geography <- population_pyramides |>
  group_by(geography) |>
  summarise(
    population_total = sum(population, na.rm = TRUE),
    population_men = sum(population[gender == "Men+"], na.rm = TRUE),
    population_women = sum(population[gender == "Women+"], na.rm = TRUE),
    population_0_14 = sum(population[age_group %in% age_groups_0_14], na.rm = TRUE),
    population_15_64 = sum(population[age_group %in% age_groups_15_64], na.rm = TRUE),
    population_65_plus = sum(population[age_group %in% age_groups_65_plus], na.rm = TRUE),
    largest_age_group = as.character(age_group[which.max(population)]),
    largest_age_group_population = max(population, na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(
    pct_0_14 = population_0_14 / population_total,
    pct_15_64 = population_15_64 / population_total,
    pct_65_plus = population_65_plus / population_total,
    old_age_dependency_per_100 = 100 * population_65_plus / population_15_64,
    youth_dependency_per_100 = 100 * population_0_14 / population_15_64,
    women_per_100_men = 100 * population_women / population_men
  )

median_average_age <- population_clean |>
  filter(
    geography %in% c("Canada", "Quebec"),
    year == latest_year,
    gender == "Total - gender",
    age_group %in% c("Median age", "Average age"),
    unit == "Years"
  ) |>
  select(geography, age_group, value) |>
  pivot_wider(
    names_from = age_group,
    values_from = value
  ) |>
  rename(
    median_age = `Median age`,
    average_age = `Average age`
  )

indicators_2025 <- total_by_geography |>
  left_join(median_average_age, by = "geography") |>
  mutate(
    year = latest_year,
    source_table = table_id,
    access_date = access_date,
    .before = 1
  ) |>
  arrange(geography)

age_gender_summary <- population_pyramides |>
  group_by(geography, age_group, gender) |>
  summarise(
    population = sum(population, na.rm = TRUE),
    proportion = sum(proportion, na.rm = TRUE),
    .groups = "drop"
  ) |>
  arrange(geography, age_group, gender)

comparison_indicators <- population_comparison |>
  group_by(year, geography) |>
  summarise(
    population_total = sum(population, na.rm = TRUE),
    population_65_plus = sum(population[age_group %in% age_groups_65_plus], na.rm = TRUE),
    pct_65_plus = population_65_plus / population_total,
    .groups = "drop"
  )

summary_dataset <- tibble::tibble(
  metric = c(
    "source_page",
    "catalogue_page",
    "doi_url",
    "access_date",
    "table_id",
    "release_date",
    "date_modified",
    "frequency",
    "raw_rows",
    "raw_columns",
    "prepared_latest_rows",
    "prepared_latest_columns",
    "comparison_rows",
    "comparison_columns",
    "first_year",
    "latest_year",
    "n_geographies_raw",
    "n_gender_categories_raw",
    "canada_population_2025",
    "quebec_population_2025",
    "canada_pct_65_plus_2025",
    "quebec_pct_65_plus_2025",
    "canada_median_age_2025",
    "quebec_median_age_2025"
  ),
  value = c(
    source_page,
    catalogue_page,
    doi_url,
    access_date,
    table_id,
    "2025-09-24",
    "2026-06-21",
    "Annuelle",
    as.character(nrow(population_raw)),
    as.character(ncol(population_raw)),
    as.character(nrow(population_pyramides)),
    as.character(ncol(population_pyramides)),
    as.character(nrow(population_comparison)),
    as.character(ncol(population_comparison)),
    as.character(min(as.integer(population_raw$REF_DATE), na.rm = TRUE)),
    as.character(latest_year),
    as.character(n_distinct(population_raw$GEO)),
    as.character(n_distinct(population_raw$Gender)),
    as.character(indicators_2025$population_total[indicators_2025$geography == "Canada"]),
    as.character(indicators_2025$population_total[indicators_2025$geography == "Quebec"]),
    as.character(indicators_2025$pct_65_plus[indicators_2025$geography == "Canada"]),
    as.character(indicators_2025$pct_65_plus[indicators_2025$geography == "Quebec"]),
    as.character(indicators_2025$median_age[indicators_2025$geography == "Canada"]),
    as.character(indicators_2025$median_age[indicators_2025$geography == "Quebec"])
  )
)

stopifnot(
  nrow(population_raw) == 302610,
  ncol(population_raw) == 24,
  latest_year == 2025L,
  n_distinct(population_raw$GEO) == 15L,
  setequal(unique(population_raw$Gender), c("Total - gender", "Men+", "Women+")),
  setequal(unique(population_raw$UOM), c("Persons", "Years")),
  nrow(population_pyramides) == 84L,
  ncol(population_pyramides) == 8L,
  nrow(population_comparison) == 168L,
  nrow(indicators_2025) == 2L,
  all(indicators_2025$population_total > 0),
  all(indicators_2025$pct_65_plus > 0.15),
  all(indicators_2025$pct_65_plus < 0.25)
)

write_csv(population_pyramides, latest_path)
write_csv(population_comparison, comparison_path)
write_csv(indicators_2025, indicators_path)
write_csv(age_gender_summary, age_gender_path)
write_csv(comparison_indicators, file.path(processed_dir, "evolution_65_plus_quebec_canada.csv"))
write_csv(summary_dataset, summary_path)

message("Source : ", source_page)
message("DOI : ", doi_url)
message("Fichier brut : ", raw_path)
message("Fichier préparé : ", latest_path)
message("Lignes brutes : ", nrow(population_raw))
message("Lignes préparées 2025 : ", nrow(population_pyramides))
message("Dernière année disponible : ", latest_year)

record_preparation("pyramides-ages")
