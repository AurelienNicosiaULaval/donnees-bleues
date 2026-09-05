# Comparer la structure d'âge du Québec et du Canada
# Ouvrir le projet RStudio de l’archive, puis exécuter ce script.
# Source : https://www150.statcan.gc.ca/t1/tbl1/fr/tv.action?pid=1710000501
# Les données de classe sont figées; ce script ne les télécharge pas.

# Load libraries
library(dplyr)
library(ggplot2)
library(readr)
library(scales)

# Prepare official table

# Import prepared files
population_2025 <- read_csv(
  "data/processed/pyramides-ages/population_pyramides_quebec_canada_latest.csv",
  show_col_types = FALSE
)

evolution_65_plus <- read_csv(
  "data/processed/pyramides-ages/evolution_65_plus_quebec_canada.csv",
  show_col_types = FALSE
)

population_2025$age_group <- factor(population_2025$age_group, levels = c(paste(seq(0,95,5), "to", seq(4,99,5), "years"), "100 years and older"))

# Plot pyramids by geography
print(ggplot(
  population_2025,
  aes(x = age_group, y = proportion_plot, fill = gender)
) +
  geom_col(width = 0.85) +
  coord_flip() +
  facet_wrap(vars(geography)) +
  scale_y_continuous(labels = function(x) percent(abs(x), accuracy = 1)) +
  labs(
    title = "Pyramides des âges, 2025",
    subtitle = "Canada et Québec, proportions de la population estimée au 1er juillet",
    x = "Groupe d'âge",
    y = "Part de la population",
    fill = "Genre publié"
  ) +
  theme_minimal())

# Compare the share aged 65 and over
print(evolution_65_plus |>
  mutate(pct_65_plus = percent(pct_65_plus, accuracy = 0.1)))
