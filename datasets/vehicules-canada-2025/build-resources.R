# Reconstruire uniquement les ressources de ce jeu, après preparation.R.
# Exécuter depuis la racine de Données bleues.
library(readr)
library(ggplot2)
library(yaml)
source("R/utils_classroom.R")
source("R/utils_publication.R")
source("R/utils_dataset_charts.R")

id <- "vehicules-canada-2025"
metadata <- read_yaml(file.path("datasets", id, "metadata.yml"))
build_classroom_kit(metadata)
status <- system2(file.path(R.home("bin"), "Rscript"),
  c("scripts/build_public_previews.R", id))
stopifnot(status == 0L)
preview <- validate_public_preview(metadata)
chart <- build_dataset_chart(preview, metadata)
ggsave(file.path("assets/charts", paste0(id, ".svg")), chart,
  width = 8, height = 5, device = svglite::svglite)

# Vignette statistique originale fondée sur les 64 configurations.
vignette <- ggplot(preview, aes(engine_size_l, combined_l_per_100km, colour = vehicle_class_group)) +
  geom_point(size = 2.4, alpha = .8) +
  scale_colour_manual(values = c("#0072B2", "#D55E00", "#009E73", "#CC79A7", "#E69F00")) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "none", axis.title = element_blank(),
    axis.text = element_blank(), panel.grid.minor = element_blank(),
    plot.background = element_rect(fill = "#f2f7fb", colour = NA))
ggsave(file.path("assets/cards", paste0(id, ".png")), vignette,
  width = 8, height = 4.5, dpi = 160)
message("Trousse, aperçu et graphiques du jeu Véhicules construits.")
