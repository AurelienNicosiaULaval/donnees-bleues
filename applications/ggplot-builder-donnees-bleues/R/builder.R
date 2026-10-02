# The displayed, downloaded and rendered plot all use the same generated code.
# Only whitelisted controls and quoted labels enter that code.
source_url <- paste0(
  "https://raw.githubusercontent.com/AurelienNicosiaULaval/",
  "arbres_quebec/v1.0.0/data_clean/arbres_quebec_small.csv"
)

species_levels <- c(
  "Bouleau à papier (blanc)", "Sapin baumier", "Épinette noire", "Érable rouge"
)
species_labels <- c("Bouleau à papier", "Sapin baumier", "Épinette noire", "Érable rouge")
variable_labels <- c(
  diametre_cm = "Diamètre à hauteur de poitrine (cm)",
  hauteur_m = "Hauteur observée (m)", age_ans = "Âge publié (ans)"
)
palettes <- list(
  foret = c("#007C83", "#487A39", "#4263A4", "#C16A32"),
  bleue = c("#176B87", "#5870B3", "#844995", "#A15525"),
  accessible = c("#0072B2", "#009E73", "#CC79A7", "#D55E00")
)
mode_labels <- c(
  portrait = "Boîtes et observations", points = "Nuage de points",
  violon = "Violons", densite = "Courbes de densité", histogramme = "Histogrammes"
)

r_quote <- function(x) paste(sub("[[:blank:]]+$", "", capture.output(dput(as.character(x)))), collapse = "\n")

read_trees <- function(path) {
  readr::read_csv(path, show_col_types = FALSE, col_types = readr::cols(
    .default = readr::col_guess(), plot_id = readr::col_character(),
    tree_id = readr::col_character(), record_id = readr::col_character()
  ))
}

normalize_config <- function(config) {
  config$mode <- match.arg(config$mode, names(mode_labels))
  config$x <- match.arg(config$x, names(variable_labels))
  config$y <- match.arg(config$y, names(variable_labels))
  config$palette <- match.arg(config$palette, names(palettes))
  config$theme <- match.arg(config$theme, c("bleues", "minimal", "classic", "gray"))
  config$species <- species_labels[species_labels %in% config$species]
  config$stage <- as.integer(config$stage)
  stopifnot(config$stage %in% 1:5, is.finite(config$alpha),
            config$alpha >= 0.1, config$alpha <= 1,
            is.finite(config$size), config$size >= 1, config$size <= 5,
            config$bins %in% 5:40)
  config
}

default_config <- function() list(
  mode = "portrait", x = "diametre_cm", y = "hauteur_m", palette = "foret",
  theme = "bleues", species = species_labels, stage = 5L, alpha = 0.65,
  size = 2.5, bins = 18L, points = TRUE, mean = TRUE, smooth = FALSE,
  facet = FALSE, flip = TRUE, colour = TRUE,
  compact = FALSE, title = "Quatre espèces, quatre silhouettes",
  subtitle = "Comparer les hauteurs en gardant chaque arbre visible"
)

make_transform_code <- function(config) {
  cfg <- normalize_config(config)
  numeric_vars <- if (cfg$mode == "points") unique(c(cfg$x, cfg$y)) else cfg$y
  predicates <- c(
    paste0("espece %in% ", r_quote(cfg$species)),
    paste0("!is.na(", numeric_vars, ")")
  )
  paste0(
    "donnees <- arbres |>\n",
    "  mutate(\n",
    "    espece = factor(species_fr,\n",
    "      levels = ", r_quote(species_levels), ",\n",
    "      labels = ", r_quote(species_labels), "),\n",
    "    diametre_cm = diameter_cm,\n",
    "    hauteur_m = height_m,\n",
    "    age_ans = age_years\n",
    "  ) |>\n",
    "  filter(\n    ", paste(predicates, collapse = ",\n    "), "\n  )"
  )
}

make_plot_code <- function(config) {
  cfg <- normalize_config(config)
  grouped <- cfg$stage >= 3L && cfg$colour
  overlay <- cfg$stage >= 4L
  finishing <- cfg$stage >= 5L
  category_mode <- cfg$mode %in% c("portrait", "violon")
  aes_parts <- if (category_mode) {
    c("x = espece", paste0("y = ", cfg$y))
  } else if (cfg$mode == "points") {
    c(paste0("x = ", cfg$x), paste0("y = ", cfg$y))
  } else paste0("x = ", cfg$y)
  if (grouped) aes_parts <- c(aes_parts,
    if (cfg$mode == "points") "colour = espece" else "fill = espece, colour = espece")
  layers <- character()
  num <- function(x) format(x, scientific = FALSE, trim = TRUE, decimal.mark = ".")
  if (cfg$stage >= 2L) {
    layers <- switch(cfg$mode,
      portrait = paste0("geom_boxplot(width = 0.5, outlier.shape = ",
        if (overlay && cfg$points) "NA" else "19",
        ", alpha = 0.18, linewidth = 0.65)"),
      violon = "geom_violin(width = 0.8, trim = TRUE, alpha = 0.2, linewidth = 0.65)",
      points = paste0("geom_point(size = ", num(cfg$size), ", alpha = ", num(cfg$alpha), ")"),
      densite = paste0("geom_density(alpha = ", num(cfg$alpha * 0.35), ", linewidth = 1)"),
      histogramme = paste0("geom_histogram(bins = ", cfg$bins,
        ", position = ", r_quote(if (overlay && cfg$facet) "stack" else "identity"),
        ", alpha = ", num(if (grouped && !(overlay && cfg$facet)) min(cfg$alpha, 0.4) else cfg$alpha), ")")
    )
    if (category_mode && overlay) {
      if (cfg$points) layers <- c(layers, paste0(
        "geom_point(position = position_jitter(width = 0.12, height = 0, seed = 2026),\n",
        "    size = ", num(cfg$size), ", alpha = ", num(cfg$alpha), ")"))
      if (cfg$mean) layers <- c(layers,
        "stat_summary(fun = mean, geom = \"point\", shape = 23,\n    size = 4, fill = \"white\", colour = \"#172B3A\", stroke = 0.9)")
    }
    if (cfg$mode == "points" && overlay && cfg$smooth) layers <- c(layers,
      "geom_smooth(method = \"lm\", formula = y ~ x, se = FALSE, linewidth = 0.8)")
  }
  if (grouped) {
    values <- paste0("c(", paste(vapply(palettes[[cfg$palette]], r_quote, ""), collapse = ", "), ")")
    scale_args <- paste0("values = setNames(", values, ", ", r_quote(species_labels), "),\n    drop = FALSE")
    layers <- c(layers, paste0("scale_colour_manual(", scale_args, ")"))
    if (cfg$mode != "points") layers <- c(layers, paste0("scale_fill_manual(", scale_args, ")"))
  }
  if (overlay && cfg$facet && !category_mode) layers <- c(layers,
    "facet_wrap(vars(espece), ncol = 2, drop = FALSE)")
  if (overlay && cfg$flip && category_mode) layers <- c(layers, "coord_flip()")
  if (finishing) {
    compact <- isTRUE(cfg$compact)
    wrap_label <- function(label, width) if (compact) paste(strwrap(label, width = width), collapse = "\n") else label
    x_label <- if (category_mode) "" else if (cfg$mode == "points") variable_labels[[cfg$x]] else variable_labels[[cfg$y]]
    y_label <- if (cfg$mode == "densite") "Densité" else if (cfg$mode == "histogramme") "Nombre d’arbres" else variable_labels[[cfg$y]]
    caption <- "MRNF / PET5 · sélection pédagogique v1.0.0 · CC BY 4.0\n50 arbres sélectionnés par espèce; représentativité provinciale non établie."
    if (compact) caption <- paste(vapply(strsplit(caption, "\n", fixed = TRUE)[[1]],
      function(line) paste(strwrap(line, width = 44), collapse = "\n"), ""), collapse = "\n")
    layers <- c(layers, paste0(
      "labs(\n    title = ", r_quote(wrap_label(cfg$title, 34)), ",\n    subtitle = ", r_quote(wrap_label(cfg$subtitle, 38)),
      ",\n    x = ", r_quote(wrap_label(x_label, 30)), ", y = ", r_quote(wrap_label(y_label, 30)),
      if (grouped) paste0(",\n    colour = \"Espèce\"", if (cfg$mode != "points") ", fill = \"Espèce\"" else "") else "",
      ",\n    caption = ", r_quote(caption), "\n  )"))
    layers <- c(layers, switch(cfg$theme,
      bleues = paste0("theme_minimal(base_size = ", if (compact) 9 else 13, ")"),
      minimal = paste0("theme_minimal(base_size = ", if (compact) 9 else 13, ")"),
      classic = paste0("theme_classic(base_size = ", if (compact) 9 else 13, ")"),
      gray = paste0("theme_gray(base_size = ", if (compact) 9 else 13, ")")))
    if (compact) layers <- c(layers,
      "theme(plot.title.position = \"plot\", plot.caption.position = \"plot\")")
    if (cfg$theme == "bleues") layers <- c(layers, paste0(
      "theme(\n    panel.grid.minor = element_blank(),\n",
      "    panel.grid.major.y = element_blank(),\n",
      "    plot.title = element_text(face = \"bold\", size = ", if (compact) 12 else 19, ", colour = \"#172B3A\"),\n",
      "    plot.subtitle = element_text(colour = \"#526579\", margin = margin(b = 18)),\n",
      "    plot.caption = element_text(size = ", if (compact) 7 else 9, ", colour = \"#526579\", hjust = 0, margin = margin(t = 16)),\n",
      "    strip.text = element_text(face = \"bold\", colour = \"#172B3A\"),\n",
      "    plot.margin = margin(18, 18, 12, 14)\n  )"))
    layers <- c(layers, paste0("theme(legend.position = ",
      r_quote(if (category_mode || (overlay && cfg$facet)) "none" else "bottom"), ")"))
  }
  paste0("graphique <- ggplot(donnees, aes(", paste(aes_parts, collapse = ", "), "))",
    if (length(layers)) paste0(" +\n  ", paste(layers, collapse = " +\n  ")) else "",
    "\n\ngraphique")
}

build_view <- function(config, trees) {
  cfg <- normalize_config(config)
  transform_code <- make_transform_code(cfg)
  plot_code <- make_plot_code(cfg)
  # The code is generated from a fixed grammar, never from a free-form R editor.
  env <- new.env(parent = globalenv())
  env$arbres <- trees
  eval(parse(text = transform_code), envir = env)
  selected_count <- sum(trees$species_fr %in% species_levels[species_labels %in% cfg$species])
  list(plot = eval(parse(text = plot_code), envir = env), data = env$donnees,
       excluded = selected_count - nrow(env$donnees), selected = selected_count,
       code = paste(transform_code, plot_code, sep = "\n\n"))
}

export_script <- function(config) {
  paste0(
    "# ggplot builder | Données bleues\n",
    "# Source : MRNF / PET5, jeu pédagogique d’Aurélien Nicosia, version 1.0.0.\n",
    "# Données et adaptations : CC BY 4.0. Taxonomie VASCAN : CC0 1.0.\n",
    "# Échantillon équilibré pour l’enseignement, sans représentativité provinciale établie.\n",
    "# L’âge manque pour 52 arbres, dont tous les érables rouges.\n\n",
    "library(ggplot2)\nlibrary(dplyr)\nlibrary(readr)\n\n",
    "arbres <- read_csv(\n  ", r_quote(source_url), ",\n",
    "  col_types = cols(.default = col_guess(), plot_id = col_character(),\n",
    "    tree_id = col_character(), record_id = col_character()),\n",
    "  show_col_types = FALSE\n)\n\n",
    make_transform_code(config), "\n\n", make_plot_code(config)
  )
}
