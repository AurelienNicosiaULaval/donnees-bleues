# Vignette calculée sur la version référencée, sans télécharger ni republier le CSV.
# Rscript scripts/build_hydro_quebec_card.R chemin/vers/demande_temperature_horaire.csv
library(readr)
library(dplyr)
library(ggplot2)
library(yaml)
library(digest)

arguments <- commandArgs(trailingOnly = TRUE)
if (length(arguments) != 1L) stop("Indiquer le chemin du CSV vérifié.", call. = FALSE)
metadata <- read_yaml("datasets/hydro-quebec-temperature/metadata.yml")
stopifnot(digest(file = arguments[[1L]], algo = "sha256") == metadata$verification$sha256)
daily <- read_csv(arguments[[1L]], na = "", show_col_types = FALSE) |>
  filter(annee == 2024) |>
  group_by(date_locale) |>
  filter(n() == 24L, all(!is.na(demande_mw)), all(!is.na(temp_ponderee))) |>
  summarise(temperature = mean(temp_ponderee), demand_gw = mean(demande_mw) / 1000,
            .groups = "drop")

card <- ggplot(daily, aes(temperature, demand_gw)) +
  geom_point(colour = "#2879a3", alpha = 0.65, size = 2.2) +
  labs(title = "Électricité et température", subtitle = "Moyennes quotidiennes · 2024 · journées complètes",
       x = "Température pondérée (°C)", y = "Demande moyenne (GW)") +
  theme_minimal(base_size = 16) +
  theme(plot.background = element_rect(fill = "#f2f7fa", colour = NA),
        panel.grid.minor = element_blank(), panel.grid.major = element_line(colour = "#dbe5ec"),
        plot.title = element_text(colour = "#153449", size = 23),
        plot.subtitle = element_text(colour = "#526776", size = 13),
        axis.title = element_text(size = 13), plot.margin = margin(16, 22, 12, 12))
ggsave("assets/cards/hydro-quebec-temperature.png", card, width = 10.67, height = 6,
       units = "in", dpi = 120, bg = "#f2f7fa")
message(nrow(daily), " journées complètes représentées.")
