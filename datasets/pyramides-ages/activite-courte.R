# Pyramide des âges du Québec en 2025
# Ouvrir le projet RStudio de l’archive, puis exécuter ce script.
# Source : https://www150.statcan.gc.ca/t1/tbl1/fr/tv.action?pid=1710000501
# Les données de classe sont figées; ce script ne les télécharge pas.

# Load libraries
library(dplyr)
library(ggplot2)
library(readr)
library(scales)

# Prepare and import data

population <- read_csv(
  "data/processed/pyramides-ages/population_pyramides_quebec_canada_latest.csv",
  show_col_types = FALSE
)

population$age_group <- factor(population$age_group, levels = c(paste(seq(0,95,5), "to", seq(4,99,5), "years"), "100 years and older"))

population_quebec <- population |>
  filter(geography == "Quebec")


# Check the structure
print(population_quebec |>
  count(year, gender))

# Build the pyramid
print(ggplot(
  population_quebec,
  aes(x = age_group, y = proportion_plot, fill = gender)
) +
  geom_col(width = 0.85) +
  coord_flip() +
  scale_y_continuous(labels = function(x) percent(abs(x), accuracy = 1)) +
  labs(
    title = "Pyramide des âges du Québec, 2025",
    subtitle = "Proportions de la population estimée au 1er juillet",
    x = "Groupe d'âge",
    y = "Part de la population",
    fill = "Genre publié"
  ) +
  theme_minimal())
