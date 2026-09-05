# Vignette statistique originale : aucun ajout de photographie externe.
# Données MRNF / PET5 adaptées par Aurélien Nicosia, arbres_quebec v1.0.0.
library(readr)
library(ggplot2)
arbres <- read_csv("data/processed/arbres-quebec/arbres_quebec_small.csv",
  col_types = cols(.default = col_skip(), species = col_character(),
                   diameter_cm = col_double(), height_m = col_double()))
stopifnot(nrow(arbres) == 200, !anyNA(arbres))
figure <- ggplot(arbres, aes(diameter_cm, height_m, colour = species)) +
  geom_point(size = 2, alpha = .8) + scale_colour_brewer(palette = "Dark2") +
  theme_minimal(base_size = 12) +
  theme(legend.position = "none", axis.title = element_blank(),
        axis.text = element_blank(), panel.grid.minor = element_blank(),
        plot.background = element_rect(fill = "#f3f8f6", colour = NA))
ggsave("assets/cards/arbres-quebec.png", figure, width = 8, height = 4.5, dpi = 160)
