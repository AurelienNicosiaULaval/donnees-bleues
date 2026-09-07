# Reconstruire après preparation.R, depuis la racine de Données bleues.
library(readr)
library(dplyr)
library(ggplot2)
library(yaml)
source("R/utils_classroom.R")
source("R/utils_publication.R")
source("R/utils_dataset_charts.R")
id <- "empress-of-ireland"
metadata <- read_yaml(file.path("datasets", id, "metadata.yml"))
build_classroom_kit(metadata)
status <- system2(file.path(R.home("bin"), "Rscript"), c("scripts/build_public_previews.R", id))
stopifnot(status == 0L)
preview <- validate_public_preview(metadata)
chart <- build_dataset_chart(preview, metadata)
ggsave(file.path("assets/charts", paste0(id, ".svg")), chart,
  width = 8, height = 5, device = svglite::svglite)
portrait <- preview |> group_by(class) |>
  summarise(proportion = sum(frequency[survived == 1]) / sum(frequency), .groups = "drop") |>
  mutate(classe = factor(class, c("first", "second", "third"), c("1re", "2e", "3e")))
vignette <- ggplot(portrait, aes(classe, proportion)) +
  geom_col(fill = "#0072B2", width = .65) +
  geom_text(aes(label = paste0(round(100 * proportion, 1), " %")), vjust = -.5) +
  scale_y_continuous(limits = c(0, .5), labels = function(x) paste0(100*x, " %")) +
  labs(x = "Classe des passagers", y = "Proportion de survivants") +
  theme_minimal(base_size = 14) +
  theme(panel.grid.minor = element_blank(),
    plot.background = element_rect(fill = "#f2f7fb", colour = NA))
ggsave(file.path("assets/cards", paste0(id, ".png")), vignette, width = 8, height = 4.5, dpi = 160)
message("Trousse, aperçu et graphiques Empress of Ireland construits.")
