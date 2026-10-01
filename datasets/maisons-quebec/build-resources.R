# Construire les ressources de Maisons du Québec depuis la racine du dépôt.
# Préparation préalable : source("datasets/maisons-quebec/preparation.R").
library(readr)
library(dplyr)
library(ggplot2)
library(yaml)
library(digest)
library(jsonlite)
library(svglite)
source("R/utils_classroom.R")
source("R/utils_publication.R")
source("R/utils_dataset_charts.R")

id <- "maisons-quebec"
metadata <- read_yaml(file.path("datasets", id, "metadata.yml"))
for (directory in c("assets/data", "assets/charts", "assets/cards")) {
  dir.create(directory, recursive = TRUE, showWarnings = FALSE)
}
stopifnot(file.copy(metadata$processed_file, "assets/data/maisons-quebec.csv", overwrite = TRUE))
build_classroom_kit(metadata)
# Réutiliser le constructeur commun en limitant explicitement la sélection au nouveau jeu.
status <- system2(file.path(R.home("bin"), "Rscript"),
  c("--vanilla", "scripts/build_public_previews.R", id))
stopifnot(status == 0L)
preview <- validate_public_preview(metadata)
ggsave(file.path("assets/charts", paste0(id, ".svg")),
  build_dataset_chart(preview, metadata), width = 8, height = 5, device = svglite)

# Vignette basée sur les 600 observations, avec axes logarithmiques pour la lisibilité.
data <- read_csv(metadata$processed_file, show_col_types = FALSE)
card <- ggplot(data, aes(x = aire_etages_m2, y = valeur_fonciere_cad)) +
  geom_point(colour = "#185b83", alpha = 0.45, size = 1.4) +
  scale_x_log10(labels = scales::label_number(big.mark = " ")) +
  scale_y_log10(labels = scales::label_number(big.mark = " ")) +
  labs(title = "600 maisons à Québec", subtitle = "Valeurs au rôle 2025 · référence au 1er juillet 2023",
    x = "Aire d'étages brute (m²)", y = "Valeur évaluée (CAD)") +
  theme_minimal(base_size = 13) +
  theme(panel.grid.minor = element_blank(), plot.background = element_rect(fill = "white", colour = NA))
ggsave("assets/cards/maisons-quebec.png", card, width = 8, height = 4.5, dpi = 160)
message("Trousse, CSV complet, aperçu, graphique et vignette calculée construits.")
