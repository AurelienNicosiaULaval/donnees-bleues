# Run from this directory: Rscript verifier.R
library(ggplot2)
library(dplyr)
library(readr)
source("R/builder.R")

trees <- read_trees("data/arbres_quebec.csv")
stopifnot(nrow(trees) == 200L, ncol(trees) == 21L,
          all(table(trees$species_fr) == 50L),
          sum(is.na(trees$age_years)) == 52L,
          all(is.na(trees$age_years[trees$species_fr == "Érable rouge"])))

# Exercise geometry, progressive layers, missing ages, palettes and grouping.
cases <- expand.grid(mode = names(mode_labels), stage = 1:5,
                     y = names(variable_labels), colour = c(TRUE, FALSE),
                     stringsAsFactors = FALSE)
for (i in seq_len(nrow(cases))) {
  cfg <- modifyList(default_config(), as.list(cases[i, ]))
  cfg$facet <- TRUE
  cfg$smooth <- TRUE
  cfg$palette <- names(palettes)[(i - 1L) %% length(palettes) + 1L]
  view <- build_view(cfg, trees)
  stopifnot(nrow(view$data) == if (cfg$y == "age_ans") 148L else 200L)
  built <- ggplot_build(view$plot)
  stopifnot(length(built$data) >= 1L)
}

# Narrow-screen typography must also produce complete renderable graphics.
for (mode in names(mode_labels)) {
  cfg <- default_config()
  cfg$mode <- mode
  cfg$compact <- TRUE
  stopifnot(inherits(ggplotGrob(build_view(cfg, trees)$plot), "gtable"))
}

# An age plot retains the missing-data warning's exact count.
cfg <- default_config()
cfg$y <- "age_ans"
view <- build_view(cfg, trees)
stopifnot(view$excluded == 52L, view$selected == 200L,
          !any(view$data$espece == "Érable rouge"))
cfg$species <- "Érable rouge"
stopifnot(nrow(build_view(cfg, trees)$data) == 0L)
cfg$species <- character()
stopifnot(build_view(cfg, trees)$selected == 0L)

# Re-running the generated plot must reproduce the displayed layer data.
cfg <- default_config()
cfg$title <- 'Un titre avec "guillemets", une apostrophe et \\ un retour\nà la ligne'
view <- build_view(cfg, trees)
replay <- new.env(parent = globalenv())
replay$arbres <- trees
invisible(eval(parse(text = view$code), replay))
stopifnot(identical(ggplot_build(view$plot)$data, ggplot_build(replay$graphique)$data),
          identical(replay$graphique$labels$title, cfg$title))

# Full downloadable script: real import from the immutable versioned source.
exported <- new.env(parent = globalenv())
invisible(eval(parse(text = export_script(cfg)), exported))
stopifnot(identical(lapply(exported$arbres, identity), lapply(trees, identity)),
          identical(ggplot_build(view$plot)$data, ggplot_build(exported$graphique)$data))

# Save the default reproducible example and its visual preview.
writeLines(export_script(default_config()), "exemple-graphique.R", useBytes = TRUE)
ggsave("apercu.png", build_view(default_config(), trees)$plot,
       width = 11, height = 7, dpi = 140, bg = "white")
cat(nrow(cases), "configurations graphiques vérifiées.\n")
cat("Données, âges manquants, sélections vides et export R : OK.\n")
