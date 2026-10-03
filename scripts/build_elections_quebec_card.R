# Vignette calculée sur la dernière capture du CSV référencé dans la fiche.
# Rscript scripts/build_elections_quebec_card.R chemin/vers/candidates.csv
library(readr)
library(dplyr)
library(ggplot2)
library(yaml)
library(digest)

arguments <- commandArgs(trailingOnly = TRUE)
if (length(arguments) != 1L) stop("Indiquer le chemin du CSV vérifié.", call. = FALSE)
metadata <- read_yaml("datasets/elections-quebec/metadata.yml")
stopifnot(digest(file = arguments[[1L]], algo = "sha256") == metadata$verification$sha256)

districts <- read_csv(
  arguments[[1L]], col_types = cols(.default = col_character()),
  na = "NA", trim_ws = FALSE, show_col_types = FALSE
) |>
  group_by(election_id, source_id) |>
  filter(observed_at == max(observed_at)) |>
  ungroup() |>
  count(district_id, name = "candidatures")
stopifnot(
  nrow(districts) == metadata$verification$latest_districts,
  sum(districts$candidatures) == metadata$verification$latest_rows
)

card <- ggplot(districts, aes(candidatures)) +
  geom_bar(fill = "#2879a3", width = 0.75) +
  scale_x_continuous(breaks = 5:13) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.08))) +
  labs(
    title = "Candidatures par circonscription",
    subtitle = "Élections du Québec · capture du 3 octobre 2026",
    x = "Nombre de candidatures", y = "Circonscriptions"
  ) +
  theme_minimal(base_size = 16) +
  theme(
    plot.background = element_rect(fill = "#f2f7fa", colour = NA),
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank(),
    panel.grid.major.y = element_line(colour = "#dbe5ec"),
    plot.title = element_text(colour = "#153449", size = 23),
    plot.subtitle = element_text(colour = "#526776", size = 13),
    axis.title = element_text(size = 13),
    plot.margin = margin(16, 22, 12, 12)
  )
ggsave(
  "assets/cards/elections-quebec.png", card,
  width = 10.67, height = 6, units = "in", dpi = 120, bg = "#f2f7fa"
)
message(nrow(districts), " circonscriptions représentées.")
