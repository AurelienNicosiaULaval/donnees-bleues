# ggplot builder | Données bleues
# Source : MRNF / PET5, jeu pédagogique d’Aurélien Nicosia, version 1.0.0.
# Données et adaptations : CC BY 4.0. Taxonomie VASCAN : CC0 1.0.
# Échantillon équilibré pour l’enseignement, sans représentativité provinciale établie.
# L’âge manque pour 52 arbres, dont tous les érables rouges.

library(ggplot2)
library(dplyr)
library(readr)

arbres <- read_csv(
  "https://raw.githubusercontent.com/AurelienNicosiaULaval/arbres_quebec/v1.0.0/data_clean/arbres_quebec_small.csv",
  col_types = cols(.default = col_guess(), plot_id = col_character(),
    tree_id = col_character(), record_id = col_character()),
  show_col_types = FALSE
)

donnees <- arbres |>
  mutate(
    espece = factor(species_fr,
      levels = c("Bouleau à papier (blanc)", "Sapin baumier", "Épinette noire",
"Érable rouge"),
      labels = c("Bouleau à papier", "Sapin baumier", "Épinette noire", "Érable rouge"
)),
    diametre_cm = diameter_cm,
    hauteur_m = height_m,
    age_ans = age_years
  ) |>
  filter(
    espece %in% c("Bouleau à papier", "Sapin baumier", "Épinette noire", "Érable rouge"
),
    !is.na(hauteur_m)
  )

graphique <- ggplot(donnees, aes(x = espece, y = hauteur_m, fill = espece, colour = espece)) +
  geom_boxplot(width = 0.5, outlier.shape = NA, alpha = 0.18, linewidth = 0.65) +
  geom_point(position = position_jitter(width = 0.12, height = 0, seed = 2026),
    size = 2.5, alpha = 0.65) +
  stat_summary(fun = mean, geom = "point", shape = 23,
    size = 4, fill = "white", colour = "#172B3A", stroke = 0.9) +
  scale_colour_manual(values = setNames(c("#007C83", "#487A39", "#4263A4", "#C16A32"), c("Bouleau à papier", "Sapin baumier", "Épinette noire", "Érable rouge"
)),
    drop = FALSE) +
  scale_fill_manual(values = setNames(c("#007C83", "#487A39", "#4263A4", "#C16A32"), c("Bouleau à papier", "Sapin baumier", "Épinette noire", "Érable rouge"
)),
    drop = FALSE) +
  coord_flip() +
  labs(
    title = "Quatre espèces, quatre silhouettes",
    subtitle = "Comparer les hauteurs en gardant chaque arbre visible",
    x = "", y = "Hauteur observée (m)",
    colour = "Espèce", fill = "Espèce",
    caption = "MRNF / PET5 · sélection pédagogique v1.0.0 · CC BY 4.0\n50 arbres sélectionnés par espèce; représentativité provinciale non établie."
  ) +
  theme_minimal(base_size = 13) +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major.y = element_blank(),
    plot.title = element_text(face = "bold", size = 19, colour = "#172B3A"),
    plot.subtitle = element_text(colour = "#526579", margin = margin(b = 18)),
    plot.caption = element_text(size = 9, colour = "#526579", hjust = 0, margin = margin(t = 16)),
    strip.text = element_text(face = "bold", colour = "#172B3A"),
    plot.margin = margin(18, 18, 12, 14)
  ) +
  theme(legend.position = "none")

graphique
