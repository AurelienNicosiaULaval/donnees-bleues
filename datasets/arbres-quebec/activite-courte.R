# Explorer 200 arbres du Québec. Adaptation de l’activité d’Aurélien Nicosia,
# arbres_quebec v1.0.0 : https://github.com/AurelienNicosiaULaval/arbres_quebec/releases/tag/v1.0.0
# Source des mesures : MRNF / PET5, extraction du 25 juin 2026, CC BY 4.0.
# Les données de la trousse sont figées ; aucun téléchargement pendant l’activité.
library(readr)
library(dplyr)
library(ggplot2)

input <- "data/processed/arbres-quebec/arbres_quebec_small.csv"
# Permet aussi l’exécution depuis la page Quarto du sous-dossier.
if (!file.exists(input)) input <- file.path("../..", input)
arbres <- read_csv(input,
  col_types = cols(.default = col_guess(), plot_id = col_character(),
                   tree_id = col_character(), record_id = col_character()),
  show_col_types = FALSE)
stopifnot(nrow(arbres) == 200, ncol(arbres) == 21,
          n_distinct(arbres$plot_id) == 200, !anyDuplicated(arbres$record_id),
          !anyNA(arbres$diameter_cm), !anyNA(arbres$height_m))

# Décrire l’échantillon par espèce, sans masquer les âges manquants.
portrait <- arbres |>
  group_by(species) |>
  summarise(nombre = n(), diametre_moyen_cm = mean(diameter_cm),
            hauteur_moyenne_m = mean(height_m),
            ages_manquants = sum(is.na(age_years)), .groups = "drop")
print(portrait)
print(range(arbres$survey_year))

graphique <- ggplot(arbres, aes(diameter_cm, height_m, colour = species)) +
  geom_point(size = 2, alpha = .8) +
  scale_colour_brewer(palette = "Dark2") +
  labs(x = "Diamètre à hauteur de poitrine (cm)", y = "Hauteur observée (m)",
       colour = "Espèce") +
  theme_minimal(base_size = 12) +
  theme(legend.position = "bottom") + guides(colour = guide_legend(nrow = 2))
print(graphique)

# À explorer : médianes par espèce et facettes du nuage de points.
# Les 50 arbres par espèce résultent de la sélection pédagogique.
# Les proportions provinciales des espèces ne sont pas estimées par ce fichier.
# La surface terrière est déterminée par le diamètre, pas une mesure distincte.
