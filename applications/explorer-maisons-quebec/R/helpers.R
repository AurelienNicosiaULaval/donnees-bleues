# Fonctions communes à l'application et à ses contrôles.
library(readr)
library(dplyr)
library(ggplot2)
library(scales)

variable_labels <- c(valeur_fonciere_cad = "Valeur foncière évaluée (CAD)",
  aire_etages_m2 = "Aire d’étages brute (m²)",
  superficie_terrain_m2 = "Superficie du terrain (m²)",
  annee_construction = "Année de construction",
  nombre_etages_max = "Nombre maximal d’étages")
house_types <- c("Détaché", "Jumelé", "En rangée, un côté", "En rangée, plusieurs côtés")

read_houses <- function(path = "data/maisons-quebec.csv") {
  houses <- read_csv(path, show_col_types = FALSE, col_types = cols(
    maison_id = col_character(), arrondissement_code = col_character(),
    voisinage_code = col_character(), lien_physique_code = col_character(),
    genre_construction_code = col_character()))
  stopifnot(nrow(houses) == 600L, ncol(houses) == 19L,
    !anyDuplicated(houses$maison_id), all(houses$municipalite == "Québec"),
    all(houses$annee_role == 2025), all(houses$annee_extraction == 2026),
    all(houses$date_reference_marche == as.Date("2023-07-01")),
    all(houses$lien_physique %in% house_types))
  houses
}

explorer_settings <- function(types = house_types, years = c(1820, 2024),
                              graph = "scatter", x = "aire_etages_m2",
                              y = "valeur_fonciere_cad", log_axes = TRUE, bins = 30L) {
  if (is.null(types)) types <- character()
  stopifnot(all(types %in% house_types), length(years) == 2L,
    all(is.finite(years)), years[[1]] <= years[[2]],
    graph %in% c("scatter", "histogram", "boxplot"),
    x %in% names(variable_labels), y %in% names(variable_labels),
    length(log_axes) == 1L, !is.na(log_axes),
    length(bins) == 1L, is.finite(bins), bins >= 5L, bins <= 60L)
  list(types = types, years = as.numeric(years), graph = graph, x = x, y = y,
    log_axes = isTRUE(log_axes), bins = as.integer(bins))
}

filter_houses <- function(houses, settings) {
  houses |> filter(lien_physique %in% settings$types,
    between(annee_construction, settings$years[[1]], settings$years[[2]]))
}
plot_houses <- function(houses, settings) {
  variables <- if (settings$graph == "scatter") c(settings$x, settings$y) else settings$y
  houses |> filter(if_all(all_of(unique(variables)),
    function(value) is.finite(value) & (!settings$log_axes | value > 0)))
}
format_number_fr <- function(value, digits = 0L) {
  if (!length(value) || !is.finite(value)) return("non calculée")
  format(round(value, digits), nsmall = digits, big.mark = " ",
    decimal.mark = ",", scientific = FALSE, trim = TRUE)
}
house_summary <- function(houses) {
  list(n = nrow(houses),
    value = if (nrow(houses)) median(houses$valeur_fonciere_cad, na.rm = TRUE) else NA_real_,
    area = if (nrow(houses)) median(houses$aire_etages_m2, na.rm = TRUE) else NA_real_)
}
house_theme <- function() {
  theme_minimal(base_size = 14, base_family = "sans") +
    theme(panel.grid.minor = element_blank(), panel.grid.major = element_line(colour = "#e4e8eb"),
      axis.title = element_text(colour = "#172033"), axis.text = element_text(colour = "#45515c"),
      plot.margin = margin(18, 18, 8, 8), plot.background = element_rect(fill = "white", colour = NA))
}
make_house_plot <- function(houses, settings) {
  data <- plot_houses(houses, settings)
  if (!nrow(data)) stop("Aucune observation utilisable pour ce graphique.", call. = FALSE)
  numbers <- label_number(big.mark = " ", decimal.mark = ",")
  if (settings$graph == "scatter") {
    plot <- ggplot(data, aes(x = .data[[settings$x]], y = .data[[settings$y]])) +
      geom_point(colour = "#185b83", alpha = 0.45, size = 1.8) +
      labs(x = variable_labels[[settings$x]], y = variable_labels[[settings$y]])
    plot <- if (settings$log_axes) plot +
      scale_x_log10(labels = numbers) + scale_y_log10(labels = numbers) else plot +
      scale_x_continuous(labels = numbers) + scale_y_continuous(labels = numbers)
  } else if (settings$graph == "histogram") {
    plot <- ggplot(data, aes(x = .data[[settings$y]])) +
      geom_histogram(bins = settings$bins, fill = "#185b83", colour = "white") +
      labs(x = variable_labels[[settings$y]], y = "Nombre de maisons")
    plot <- if (settings$log_axes) plot + scale_x_log10(labels = numbers) else
      plot + scale_x_continuous(labels = numbers)
  } else {
    data <- data |> mutate(lien_physique = factor(lien_physique, levels = house_types))
    plot <- ggplot(data, aes(x = lien_physique, y = .data[[settings$y]])) +
      geom_boxplot(outlier.shape = NA, fill = "#dceaf0", colour = "#185b83") +
      geom_point(position = position_jitter(width = 0.14, height = 0, seed = 20261001),
        colour = "#185b83", alpha = 0.35, size = 1.2) +
      scale_x_discrete(labels = function(value) gsub(", ", "\n", value, fixed = TRUE)) +
      labs(x = "Type de maison", y = variable_labels[[settings$y]])
    plot <- if (settings$log_axes) plot + scale_y_log10(labels = numbers) else
      plot + scale_y_continuous(labels = numbers)
  }
  plot + house_theme()
}
plot_caption <- function(selected, settings) {
  count <- nrow(plot_houses(selected, settings)); removed <- nrow(selected) - count
  axis <- if (settings$log_axes) "Échelle logarithmique." else "Échelle brute."
  if (settings$graph == "scatter") axis <- if (settings$log_axes)
    "Axes logarithmiques." else "Axes en échelle brute."
  paste(count, "observation(s) affichée(s).", axis,
    if (removed) paste(removed, "ligne(s) exclue(s) du graphique : valeur manquante, non finie ou non positive.") else "",
    if (settings$graph == "histogram" && settings$log_axes)
      "Classes équidistantes sur l’échelle logarithmique." else "")
}
observation_question <- function(graph) {
  switch(graph,
    scatter = "La relation semble-t-elle la même pour tous les types de maisons ?",
    histogram = "La forme de la distribution change-t-elle quand on modifie l’échelle ou le nombre de classes ?",
    boxplot = "Les groupes ont-ils la même médiane, la même dispersion et le même effectif ?")
}

# Le script exporté est autonome; les entrées sont validées par explorer_settings().
export_house_code <- function(settings) {
  quote_r <- function(value) encodeString(value, quote = '"')
  label_x <- quote_r(variable_labels[[settings$x]]); label_y <- quote_r(variable_labels[[settings$y]])
  columns <- if (settings$graph == "scatter") c(settings$x, settings$y) else settings$y
  filter_values <- if (settings$log_axes) "~ is.finite(.x) & .x > 0" else "~ is.finite(.x)"
  lines <- c("# Données bleues : Explorer les maisons à Québec",
    "# MAMH, extraction 2026, rôle 2025, référence au marché : 2023-07-01.",
    "# Données : CC BY 4.0; code original : MIT. Valeurs évaluées, pas prix de vente.",
    "library(readr)", "library(dplyr)", "library(ggplot2)", "library(scales)", "",
    'fichier <- "maisons-quebec.csv"',
    'if (!file.exists(fichier)) {',
    '  download.file("https://donneesbleues.ca/assets/data/maisons-quebec.csv", fichier, mode = "wb")',
    "}",
    "maisons <- read_csv(fichier, show_col_types = FALSE, col_types = cols(",
    "  maison_id = col_character(), arrondissement_code = col_character(),",
    "  voisinage_code = col_character(), lien_physique_code = col_character(),",
    "  genre_construction_code = col_character()))",
    "stopifnot(nrow(maisons) == 600L, ncol(maisons) == 19L,",
    '  all(maisons$annee_role == 2025), all(maisons$date_reference_marche == as.Date("2023-07-01")))', "",
    paste0("types <- c(", paste(quote_r(settings$types), collapse = ", "), ")"),
    paste0("bornes <- c(", paste(settings$years, collapse = ", "), ")"),
    "maisons_filtrees <- maisons |>",
    "  filter(lien_physique %in% types, between(annee_construction, bornes[1], bornes[2]))",
    paste0("variables <- c(", paste(quote_r(unique(columns)), collapse = ", "), ")"),
    "donnees_graphique <- maisons_filtrees |>",
    paste0("  filter(if_all(all_of(variables), ", filter_values, "))"),
    'if (!nrow(donnees_graphique)) stop("Aucune observation utilisable pour ces choix.")',
    'nombres <- label_number(big.mark = " ", decimal.mark = ",")', "")
  if (settings$graph == "scatter") {
    lines <- c(lines, paste0("graphique <- ggplot(donnees_graphique, aes(x = ", settings$x, ", y = ", settings$y, ")) +"),
      '  geom_point(colour = "#185b83", alpha = 0.45, size = 1.8) +',
      paste0("  labs(x = ", label_x, ", y = ", label_y, ") +"),
      if (settings$log_axes) "  scale_x_log10(labels = nombres) + scale_y_log10(labels = nombres)" else
        "  scale_x_continuous(labels = nombres) + scale_y_continuous(labels = nombres)")
  } else if (settings$graph == "histogram") {
    lines <- c(lines, paste0("graphique <- ggplot(donnees_graphique, aes(x = ", settings$y, ")) +"),
      paste0('  geom_histogram(bins = ', settings$bins, ', fill = "#185b83", colour = "white") +'),
      paste0('  labs(x = ', label_y, ', y = "Nombre de maisons") +'),
      if (settings$log_axes) "  scale_x_log10(labels = nombres)" else "  scale_x_continuous(labels = nombres)")
  } else {
    lines <- c(lines,
      paste0("donnees_graphique <- donnees_graphique |> mutate(lien_physique = factor(lien_physique, levels = c(",
        paste(quote_r(house_types), collapse = ", "), ")))"),
      paste0("graphique <- ggplot(donnees_graphique, aes(x = lien_physique, y = ", settings$y, ")) +"),
      '  geom_boxplot(outlier.shape = NA, fill = "#dceaf0", colour = "#185b83") +',
      '  geom_point(position = position_jitter(width = 0.14, height = 0, seed = 20261001),',
      '    colour = "#185b83", alpha = 0.35, size = 1.2) +',
      '  scale_x_discrete(labels = function(value) gsub(", ", "\\n", value, fixed = TRUE)) +',
      paste0('  labs(x = "Type de maison", y = ', label_y, ") +"),
      if (settings$log_axes) "  scale_y_log10(labels = nombres)" else "  scale_y_continuous(labels = nombres)")
  }
  lines <- c(lines, "",
    "graphique <- graphique + theme_minimal(base_size = 14, base_family = \"sans\") +",
    "  theme(panel.grid.minor = element_blank(), panel.grid.major = element_line(colour = \"#e4e8eb\"),",
    "    axis.title = element_text(colour = \"#172033\"), axis.text = element_text(colour = \"#45515c\"),",
    "    plot.margin = margin(18, 18, 8, 8), plot.background = element_rect(fill = \"white\", colour = NA))",
    "print(graphique)", 'write_csv(maisons_filtrees, "maisons-filtrees.csv")',
    'ggsave("maisons-graphique.png", graphique, width = 9, height = 5.5, dpi = 160, bg = "white")',
    'cat(nrow(maisons_filtrees), "maisons retenues;", nrow(donnees_graphique), "observations affichées.\\n")')
  paste(lines, collapse = "\n")
}
