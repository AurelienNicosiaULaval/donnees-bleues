# Graphiques d'aperçu : le type et les variables proviennent de metadata.yml.
# Aucune variable ni relation temporelle n'est choisie par heuristique.
validate_chart_spec <- function(data, spec) {
  allowed <- c("count", "histogram", "scatter", "bars", "pyramid")
  if (is.null(spec) || !spec[["type"]] %in% allowed) stop("Type de graphique non déclaré.", call. = FALSE)
  for (field in c("x_variable", "x_label", "y_label", "title")) {
    if (is.null(spec[[field]]) || !nzchar(spec[[field]])) stop("Champ graphique absent : ", field, call. = FALSE)
  }
  needed <- unique(c(spec[["x_variable"]], spec[["y_variable"]], names(spec[["filter"]])))
  if (!all(needed %in% names(data))) stop("Variable graphique absente : ", paste(setdiff(needed, names(data)), collapse = ", "), call. = FALSE)
  if (spec[["type"]] == "histogram" && is.null(spec[["bins"]]) && is.null(spec[["binwidth"]])) {
    stop("Le découpage de l'histogramme doit être déclaré.", call. = FALSE)
  }
  invisible(TRUE)
}

build_dataset_chart <- function(data, metadata) {
  spec <- metadata$chart
  validate_chart_spec(data, spec)
  for (field in names(spec[["filter"]])) data <- data[data[[field]] %in% unlist(spec[["filter"]][[field]]), , drop = FALSE]
  source_rows <- nrow(data)
  # Les valeurs manquantes sont annoncées dans la légende; elles ne deviennent pas zéro.
  fields <- c(spec[["x_variable"]], spec[["y_variable"]])
  if (spec[["type"]] %in% c("histogram", "scatter", "bars", "pyramid")) {
    numeric_fields <- switch(spec[["type"]], histogram = spec[["x_variable"]], scatter = c(if (!identical(spec[["x_kind"]], "date")) spec[["x_variable"]], spec[["y_variable"]]), bars = spec[["y_variable"]], pyramid = spec[["x_variable"]])
    for (field in numeric_fields) {
      if (!is.numeric(data[[field]])) stop("Variable attendue numérique : ", field, call. = FALSE)
    }
    if (identical(spec[["x_kind"]], "date")) data[[spec[["x_variable"]]]] <- as.Date(data[[spec[["x_variable"]]]])
    keep <- stats::complete.cases(data[fields])
    for (field in numeric_fields) keep <- keep & is.finite(data[[field]])
    data <- data[keep, , drop = FALSE]
    if (!nrow(data)) stop("Aucune mesure finie à tracer : ", metadata$id, call. = FALSE)
  }
  omitted <- source_rows - nrow(data)
  if (spec[["type"]] == "count") {
    labels <- as.character(data[[spec[["x_variable"]]]])
    labels[is.na(labels) | !nzchar(labels)] <- "Non renseigné"
    counts <- as.data.frame(table(labels), stringsAsFactors = FALSE)
    names(counts) <- c("category", "n")
    plot <- ggplot2::ggplot(counts, ggplot2::aes(x = n, y = stats::reorder(category, n))) +
      ggplot2::geom_col(fill = "#185b83", width = 0.7) +
      ggplot2::scale_x_continuous(breaks = scales::breaks_pretty(n = 4), labels = scales::label_number(big.mark = " ", decimal.mark = ",")) +
      ggplot2::scale_y_discrete(labels = function(x) stringr::str_wrap(x, 32))
  } else if (spec[["type"]] == "histogram") {
    plot <- ggplot2::ggplot(data, ggplot2::aes(x = .data[[spec[["x_variable"]]]])) +
      ggplot2::geom_histogram(bins = spec[["bins"]], binwidth = spec[["binwidth"]],
                             fill = "#185b83", colour = "white", boundary = if (!is.null(spec[["binwidth"]])) 0 else NULL) +
      ggplot2::scale_x_continuous(labels = scales::label_number(big.mark = " ", decimal.mark = ","))
  } else if (spec[["type"]] == "scatter") {
    plot <- ggplot2::ggplot(data, ggplot2::aes(x = .data[[spec[["x_variable"]]]], y = .data[[spec[["y_variable"]]]])) +
      ggplot2::geom_point(colour = "#185b83", alpha = 0.8, size = 1.8)
    if (identical(spec[["x_kind"]], "date")) plot <- plot + ggplot2::scale_x_date(date_labels = "%Y-%m", breaks = scales::breaks_pretty(4)) else plot <- plot + ggplot2::scale_x_continuous(labels = scales::label_number(big.mark = " ", decimal.mark = ","))
    if (!is.null(spec[["y_limits"]])) plot <- plot + ggplot2::scale_y_continuous(limits = unlist(spec[["y_limits"]]), breaks = c(0, 6, 12, 18, 24)) else plot <- plot + ggplot2::scale_y_continuous(labels = scales::label_number(big.mark = " ", decimal.mark = ","))
  } else if (spec[["type"]] == "bars") {
    if (anyDuplicated(data[[spec[["x_variable"]]]])) stop("Le graphique par unité nécessite une clé unique.", call. = FALSE)
    data <- data[order(-data[[spec[["y_variable"]]]], data[[spec[["x_variable"]]]]), , drop = FALSE]
    if (!is.null(spec[["top_n"]])) data <- head(data, spec[["top_n"]])
    plot <- ggplot2::ggplot(data, ggplot2::aes(x = .data[[spec[["y_variable"]]]], y = stats::reorder(.data[[spec[["x_variable"]]]], .data[[spec[["y_variable"]]]]))) +
      ggplot2::geom_col(fill = "#185b83", width = 0.7) +
      ggplot2::scale_y_discrete(labels = function(x) stringr::str_wrap(gsub("—", "-", x, fixed = TRUE), 30)) +
      ggplot2::scale_x_continuous(labels = scales::label_number(big.mark = " ", decimal.mark = ","))
  } else {
    # Les classes quinquennales ont un ordre numérique, et non alphabétique.
    age_levels <- unique(data[[spec[["y_variable"]]]])
    age_levels <- age_levels[order(as.numeric(sub(" .*", "", age_levels)))]
    data[[spec[["y_variable"]]]] <- factor(data[[spec[["y_variable"]]]], levels = age_levels)
    plot <- ggplot2::ggplot(data, ggplot2::aes(x = .data[[spec[["x_variable"]]]], y = .data[[spec[["y_variable"]]]], fill = gender)) +
      ggplot2::geom_col(width = 0.8) +
      ggplot2::scale_fill_manual(values = c("Men+" = "#185b83", "Women+" = "#b95319"), labels = c("Hommes+", "Femmes+"), name = NULL) +
      ggplot2::scale_x_continuous(labels = function(x) scales::label_percent(accuracy = 0.1, decimal.mark = ",")(abs(x))) +
      ggplot2::scale_y_discrete(labels = function(x) ifelse(x == "100 years and older", "100 ans et plus", sub(" years", " ans", sub(" to ", " à ", x))))
  }
  subtitle <- if (identical(metadata$id, "retards-transport-collectif")) "Dictionnaire de variables, sans observation de retard" else paste0("Extrait consultable : ", source_rows, " lignes avant retrait des valeurs manquantes")
  caption <- paste0(omitted, " ligne(s) avec une mesure manquante ou non finie exclue(s).")
  if (!is.null(spec[["top_n"]])) caption <- paste0(caption, " Les ", spec[["top_n"]], " valeurs les plus élevées sont affichées.")
  if (spec[["type"]] == "histogram") caption <- paste0(caption, if (!is.null(spec[["binwidth"]])) paste0(" Largeur des classes : ", spec[["binwidth"]], ".") else paste0(" Découpage demandé : ", spec[["bins"]], " classes."))
  plot + ggplot2::labs(title = stringr::str_wrap(spec[["title"]], 52), subtitle = subtitle,
                       x = spec[["x_label"]], y = spec[["y_label"]], caption = stringr::str_wrap(caption, 90)) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(plot.title = ggplot2::element_text(size = 14, face = "plain", colour = "#172033"),
      plot.subtitle = ggplot2::element_text(size = 9), plot.caption = ggplot2::element_text(size = 9, hjust = 0),
      axis.title = ggplot2::element_text(size = 10), panel.grid.minor = ggplot2::element_blank(),
      legend.position = "bottom", plot.background = ggplot2::element_rect(fill = "white", colour = NA))
}
