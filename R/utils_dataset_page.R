`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0L || all(is.na(x))) y else x
}

dataset_html_escape <- function(value) {
  value <- as.character(value %||% "")
  value[is.na(value)] <- ""
  value <- gsub("&", "&amp;", value, fixed = TRUE)
  value <- gsub("<", "&lt;", value, fixed = TRUE)
  value <- gsub(">", "&gt;", value, fixed = TRUE)
  value <- gsub('"', "&quot;", value, fixed = TRUE)
  value <- gsub("'", "&#39;", value, fixed = TRUE)
  value
}

dataset_squish <- function(value, fallback = "Je ne sais pas.") {
  value <- trimws(gsub("\\s+", " ", as.character(value %||% "")))
  if (length(value) == 0L || is.na(value) || value == "") fallback else value
}

dataset_collapse <- function(value, sep = "; ") {
  value <- unlist(value %||% character(), use.names = FALSE)
  value <- trimws(as.character(value))
  value <- value[!is.na(value) & value != ""]
  paste(value, collapse = sep)
}

dataset_list <- function(value) {
  value <- unlist(value %||% character(), use.names = FALSE)
  value <- trimws(as.character(value))
  value[!is.na(value) & value != ""]
}

dataset_flag_true <- function(value) {
  value <- value %||% FALSE
  if (is.logical(value)) {
    return(isTRUE(value[[1]]))
  }

  value <- tolower(trimws(as.character(value[[1]])))
  value %in% c("true", "yes", "oui", "1")
}

dataset_find_root <- function(start) {
  start <- normalizePath(start, mustWork = FALSE)
  if (file.exists(start) && !dir.exists(start)) {
    start <- dirname(start)
  }

  current <- start
  repeat {
    if (file.exists(file.path(current, "_quarto.yml"))) {
      return(current)
    }
    parent <- dirname(current)
    if (identical(parent, current)) {
      return(getwd())
    }
    current <- parent
  }
}

dataset_current_context <- function() {
  input <- tryCatch(knitr::current_input(dir = TRUE), error = function(e) NA_character_)
  if (length(input) == 0L || is.na(input) || input == "") {
    input <- getwd()
  }

  input <- normalizePath(input, mustWork = FALSE)
  dataset_dir <- if (dir.exists(input)) input else dirname(input)
  root <- dataset_find_root(dataset_dir)

  if (!file.exists(file.path(dataset_dir, "metadata.yml"))) {
    candidates <- list.dirs(file.path(root, "datasets"), recursive = FALSE, full.names = TRUE)
    candidates <- candidates[file.exists(file.path(candidates, "metadata.yml"))]
    current_name <- basename(dirname(input))
    match <- candidates[basename(candidates) == current_name]
    if (length(match) > 0L) {
      dataset_dir <- match[[1]]
    }
  }

  root_prefix <- paste0(normalizePath(root, mustWork = FALSE), .Platform$file.sep)
  dataset_norm <- normalizePath(dataset_dir, mustWork = FALSE)
  relative_dataset <- if (startsWith(dataset_norm, root_prefix)) {
    substring(dataset_norm, nchar(root_prefix) + 1L)
  } else {
    dataset_norm
  }
  depth <- if (relative_dataset == "" || relative_dataset == ".") {
    0L
  } else {
    length(strsplit(relative_dataset, "/", fixed = TRUE)[[1]])
  }
  relative_root <- if (depth == 0L) "." else paste(rep("..", depth), collapse = "/")

  list(
    root = root,
    dataset_dir = dataset_dir,
    relative_root = relative_root
  )
}

dataset_read_metadata <- function(dataset_dir) {
  if (!requireNamespace("yaml", quietly = TRUE)) {
    stop("Le package yaml est requis.", call. = FALSE)
  }
  yaml::read_yaml(file.path(dataset_dir, "metadata.yml"))
}

dataset_score_total <- function(metadata) {
  values <- suppressWarnings(as.numeric(unlist(metadata$zero_waste %||% numeric(), use.names = FALSE)))
  total <- sum(values, na.rm = TRUE)
  if (length(values) == 0L || is.na(total)) NA_real_ else total
}

dataset_score_segments <- function(total) {
  filled <- if (is.na(total)) 0L else max(0L, min(5L, ceiling(total / 30 * 5)))
  paste(vapply(seq_len(5), function(i) {
    class <- if (i <= filled) "dataset-score-segment is-filled" else "dataset-score-segment"
    paste0('<span class="', class, '"></span>')
  }, character(1)), collapse = "")
}

dataset_image_src <- function(metadata, ctx) {
  id <- dataset_squish(metadata$id, basename(ctx$dataset_dir))
  candidates <- file.path(ctx$root, "assets", "cards", paste0(id, c(".jpg", ".jpeg", ".png", ".webp")))
  existing <- candidates[file.exists(candidates)]
  filename <- if (length(existing) > 0L) basename(existing[[1]]) else "catalogue.png"
  paste(ctx$relative_root, "assets", "cards", filename, sep = "/")
}

dataset_activity_cards <- function(metadata, ctx) {
  activity_files <- list.files(
    ctx$dataset_dir,
    pattern = "^activite-.*[.]yml$",
    full.names = TRUE
  )

  if (length(activity_files) == 0L) {
    return("")
  }

  cards <- vapply(activity_files, function(path) {
    item <- yaml::read_yaml(path)
    paste0(
      '<div class="dataset-activity-card">',
      '<span>', dataset_html_escape(dataset_squish(item$duration, "Activité")), '</span>',
      '<strong>', dataset_html_escape(dataset_squish(item$title, "Activité pédagogique")), '</strong>',
      '<p>', dataset_html_escape(dataset_squish(item$question, "Question à préciser.")), '</p>',
      '</div>'
    )
  }, character(1))

  paste(cards, collapse = "\n")
}

dataset_contributor_badge <- function(metadata) {
  if (!dataset_flag_true(metadata$stt1100_contact)) {
    return("")
  }

  name <- dataset_squish(metadata$contributor_name, "")
  if (name == "") {
    return("")
  }

  role <- dataset_squish(metadata$contributor_role, "")
  role_html <- if (role == "") "" else paste0("<small>", dataset_html_escape(role), "</small>")

  paste0(
    '<div class="dataset-contributor-badge">',
    '<span>Personne à contacter</span>',
    "<strong>", dataset_html_escape(name), "</strong>",
    role_html,
    "</div>"
  )
}

dataset_processed_csv <- function(metadata, ctx) {
  if (identical(metadata$embed_processed_preview, FALSE)) {
    return(NA_character_)
  }

  id <- dataset_squish(metadata$id, basename(ctx$dataset_dir))
  declared <- dataset_squish(metadata$processed_file %||% metadata$processed_path, "")

  candidates <- character()
  if (declared != "") {
    candidates <- c(candidates, file.path(ctx$root, declared))
  }

  candidates <- c(
    candidates,
    list.files(
      file.path(ctx$root, "data", "processed", id),
      pattern = "[.]csv$",
      full.names = TRUE
    ),
    list.files(
      file.path(ctx$dataset_dir, "data_processed"),
      pattern = "[.]csv$",
      full.names = TRUE
    )
  )

  candidates <- unique(candidates[file.exists(candidates)])
  if (length(candidates) == 0L) {
    NA_character_
  } else {
    candidates[[1]]
  }
}

dataset_relative_path <- function(path, root) {
  path <- normalizePath(path, mustWork = FALSE)
  root <- normalizePath(root, mustWork = FALSE)
  root_prefix <- paste0(root, .Platform$file.sep)
  if (startsWith(path, root_prefix)) {
    substring(path, nchar(root_prefix) + 1L)
  } else {
    path
  }
}

dataset_read_preview <- function(csv_path) {
  if (is.na(csv_path) || !file.exists(csv_path)) {
    return(NULL)
  }
  tryCatch(
    utils::read.csv(
      csv_path,
      nrows = 2500,
      stringsAsFactors = FALSE,
      check.names = FALSE
    ),
    error = function(e) NULL
  )
}

dataset_type_label <- function(x) {
  if (is.numeric(x)) {
    "num."
  } else if (inherits(x, "Date") || inherits(x, "POSIXt")) {
    "date"
  } else if (is.logical(x)) {
    "logique"
  } else {
    "cat."
  }
}

dataset_preview_table <- function(data, max_rows = 6L, max_cols = 6L) {
  if (is.null(data) || nrow(data) == 0L || ncol(data) == 0L) {
    return('<p class="dataset-empty-result">Aucun aperçu tabulaire local disponible.</p>')
  }

  data <- as.data.frame(data)
  visible <- data[seq_len(min(nrow(data), max_rows)), seq_len(min(ncol(data), max_cols)), drop = FALSE]
  header <- paste0("<th>", dataset_html_escape(names(visible)), "</th>", collapse = "")
  rows <- apply(visible, 1, function(row) {
    values <- vapply(row, function(value) {
      value <- dataset_squish(value, "")
      if (nchar(value) > 34L) paste0(substr(value, 1, 31), "...") else value
    }, character(1))
    paste0("<tr><td>", paste(dataset_html_escape(values), collapse = "</td><td>"), "</td></tr>")
  })

  paste0(
    '<div class="dataset-result-table-wrap"><table class="dataset-result-table">',
    '<thead><tr>', header, '</tr></thead>',
    '<tbody>', paste(rows, collapse = ""), '</tbody>',
    '</table></div>'
  )
}

dataset_result_stats <- function(data, metadata, csv_path, root) {
  if (!is.null(data)) {
    data <- as.data.frame(data)
    n_num <- sum(vapply(data, is.numeric, logical(1)))
    n_cat <- sum(vapply(data, function(x) is.character(x) || is.factor(x), logical(1)))
    missing_pct <- if (nrow(data) * ncol(data) == 0L) 0 else mean(is.na(data)) * 100
    source_label <- if (is.na(csv_path)) "Métadonnées" else basename(csv_path)
    stats <- list(
      "Lignes lues" = format(nrow(data), big.mark = " ", scientific = FALSE),
      "Colonnes" = format(ncol(data), big.mark = " ", scientific = FALSE),
      "Variables num." = n_num,
      "Valeurs manquantes" = paste0(round(missing_pct, 1), " %"),
      "Aperçu" = source_label
    )
  } else {
    stats <- list(
      "Lignes déclarées" = dataset_squish(metadata$n_rows),
      "Colonnes déclarées" = dataset_squish(metadata$n_cols),
      "Format" = dataset_squish(metadata$format),
      "Aperçu" = "Métadonnées"
    )
  }

  paste(vapply(names(stats), function(name) {
    paste0(
      '<div class="dataset-r-stat"><span>', dataset_html_escape(name), '</span>',
      '<strong>', dataset_html_escape(stats[[name]]), '</strong></div>'
    )
  }, character(1)), collapse = "")
}

dataset_chart_svg <- function(data, metadata) {
  if (is.null(data) || nrow(data) == 0L || ncol(data) == 0L) {
    concepts <- dataset_list(metadata$concepts)
    values <- rep(1, length(concepts))
    names(values) <- concepts
    if (length(values) == 0L) {
      return('<p class="dataset-empty-result">Graphique non disponible sans fichier préparé.</p>')
    }
    values <- head(values, 7)
    max_value <- max(values)
    bars <- paste(vapply(seq_along(values), function(i) {
      width <- 16 + (as.numeric(values[[i]]) / max_value) * 74
      y <- 18 + (i - 1) * 24
      paste0(
        '<text x="0" y="', y + 12, '" class="dataset-svg-label">', dataset_html_escape(names(values)[[i]]), '</text>',
        '<rect x="150" y="', y, '" width="', width, '" height="14" rx="3" class="dataset-svg-bar"></rect>'
      )
    }, character(1)), collapse = "")
    return(paste0('<svg class="dataset-r-chart" viewBox="0 0 320 210" role="img" aria-label="Concepts pédagogiques">', bars, '</svg>'))
  }

  data <- as.data.frame(data)
  numeric_columns <- names(data)[vapply(data, is.numeric, logical(1))]
  numeric_columns <- numeric_columns[!grepl("latitude|longitude|^id$|code", numeric_columns, ignore.case = TRUE)]
  if (length(numeric_columns) == 0L) {
    type_counts <- table(vapply(data, dataset_type_label, character(1)))
    labels <- names(type_counts)
    max_value <- max(type_counts)
    bars <- paste(vapply(seq_along(type_counts), function(i) {
      width <- 20 + (as.numeric(type_counts[[i]]) / max_value) * 210
      y <- 30 + (i - 1) * 36
      paste0(
        '<text x="0" y="', y + 14, '" class="dataset-svg-label">', dataset_html_escape(labels[[i]]), '</text>',
        '<rect x="72" y="', y, '" width="', width, '" height="18" rx="4" class="dataset-svg-bar"></rect>',
        '<text x="', 82 + width, '" y="', y + 14, '" class="dataset-svg-value">', type_counts[[i]], '</text>'
      )
    }, character(1)), collapse = "")
    return(paste0('<svg class="dataset-r-chart" viewBox="0 0 320 190" role="img" aria-label="Types de variables">', bars, '</svg>'))
  }

  preferred <- grep("ecart|taux|volume|population|nombre|^nb_|total|valeur|ratio|proportion|pourcentage", numeric_columns, ignore.case = TRUE, value = TRUE)
  y_col <- if (length(preferred) > 0L) preferred[[1]] else numeric_columns[[1]]
  y <- suppressWarnings(as.numeric(data[[y_col]]))
  keep <- which(!is.na(y))
  if (length(keep) < 2L) {
    return('<p class="dataset-empty-result">Pas assez de valeurs numériques pour tracer un aperçu.</p>')
  }

  keep <- tail(keep, min(length(keep), 40L))
  y <- y[keep]
  x <- seq_along(y)
  y_range <- range(y, na.rm = TRUE)
  if (diff(y_range) == 0) {
    y_range <- y_range + c(-0.5, 0.5)
  }

  x_svg <- 34 + (x - min(x)) / max(1, diff(range(x))) * 248
  y_svg <- 158 - (y - y_range[[1]]) / diff(y_range) * 112
  points <- paste(round(x_svg, 1), round(y_svg, 1), sep = ",", collapse = " ")

  paste0(
    '<svg class="dataset-r-chart" viewBox="0 0 320 210" role="img" aria-label="Aperçu numérique généré par R">',
    '<line x1="34" y1="158" x2="292" y2="158" class="dataset-svg-axis"></line>',
    '<line x1="34" y1="36" x2="34" y2="158" class="dataset-svg-axis"></line>',
    '<polyline points="', points, '" class="dataset-svg-line"></polyline>',
    paste(vapply(seq_along(x_svg), function(i) {
      paste0('<circle cx="', round(x_svg[[i]], 1), '" cy="', round(y_svg[[i]], 1), '" r="3.2" class="dataset-svg-point"></circle>')
    }, character(1)), collapse = ""),
    '<text x="34" y="24" class="dataset-svg-title">', dataset_html_escape(y_col), '</text>',
    '<text x="34" y="186" class="dataset-svg-label">', dataset_html_escape(format(round(y_range[[1]], 2), trim = TRUE)), '</text>',
    '<text x="230" y="186" class="dataset-svg-label">', dataset_html_escape(format(round(y_range[[2]], 2), trim = TRUE)), '</text>',
    '</svg>'
  )
}

dataset_r_code <- function(metadata, ctx, csv_path) {
  id <- dataset_squish(metadata$id, basename(ctx$dataset_dir))
  if (!is.na(csv_path) && file.exists(csv_path)) {
    relative_csv <- dataset_relative_path(csv_path, ctx$root)
    paste(
      "library(dplyr)",
      "",
      paste0('donnees <- read.csv("', relative_csv, '", check.names = FALSE)'),
      "",
      "glimpse(donnees)",
      "donnees |> summarise(lignes = n(), colonnes = ncol(donnees))",
      sep = "\n"
    )
  } else {
    paste(
      "library(yaml)",
      "",
      paste0('metadata <- yaml::read_yaml("datasets/', id, '/metadata.yml")'),
      "data.frame(",
      "  champ = c(\"theme\", \"territoire\", \"unite\", \"niveau\"),",
      "  valeur = c(metadata$theme, metadata$geography, metadata$unit, metadata$level)",
      ")",
      sep = "\n"
    )
  }
}

dataset_metadata_table <- function(metadata) {
  data <- data.frame(
    champ = c("theme", "territoire", "unite", "niveau", "format"),
    valeur = c(
      dataset_squish(metadata$theme),
      dataset_squish(metadata$geography),
      dataset_squish(metadata$unit),
      dataset_squish(metadata$level),
      dataset_squish(metadata$format)
    )
  )
  dataset_preview_table(data, max_rows = 5L, max_cols = 2L)
}

render_dataset_detail_header <- function() {
  ctx <- dataset_current_context()
  metadata <- dataset_read_metadata(ctx$dataset_dir)
  csv_path <- dataset_processed_csv(metadata, ctx)
  preview <- dataset_read_preview(csv_path)
  score <- dataset_score_total(metadata)
  score_label <- if (is.na(score)) "Je ne sais pas." else paste0(score, " / 30")
  concepts <- head(dataset_list(metadata$concepts), 7)
  projects <- head(dataset_list(metadata$idees_mini_projets), 3)
  if (length(projects) == 0L) {
    projects <- paste0("Explorer ", tolower(dataset_squish(metadata$theme, "ce jeu de données")), " avec une question descriptive.")
  }
  activities <- dataset_activity_cards(metadata, ctx)
  source_url <- dataset_squish(metadata$source_url, "")
  contributor_badge <- dataset_contributor_badge(metadata)
  source_button <- if (source_url == "") {
    ""
  } else {
    paste0('<a class="dataset-button secondary" href="', dataset_html_escape(source_url), '">Source officielle</a>')
  }

  concept_chips <- paste(vapply(concepts, function(item) {
    paste0('<span>', dataset_html_escape(item), '</span>')
  }, character(1)), collapse = "")

  project_items <- paste(vapply(projects, function(item) {
    paste0('<li>', dataset_html_escape(item), '</li>')
  }, character(1)), collapse = "")

  result_table <- if (!is.null(preview)) dataset_preview_table(preview) else dataset_metadata_table(metadata)
  data_note <- if (!is.na(csv_path) && file.exists(csv_path)) {
    paste0("Aperçu calculé par R à partir de ", dataset_html_escape(dataset_relative_path(csv_path, ctx$root)), ".")
  } else {
    "Aperçu léger calculé par R à partir des métadonnées vérifiées afin de garder la fiche rapide et stable au rendu."
  }

  cat(
    '<section class="dataset-detail-page">\n',
    '<div class="dataset-detail-hero">\n',
    '<div class="dataset-hero-copy">\n',
    '<nav class="dataset-breadcrumb"><a href="', ctx$relative_root, '/catalogue.html">Catalogue</a><span>/</span><span>',
    dataset_html_escape(dataset_squish(metadata$theme)), '</span></nav>\n',
    '<h1>', dataset_html_escape(dataset_squish(metadata$title, "Jeu de données")), '</h1>\n',
    '<p class="dataset-hero-source">', dataset_html_escape(dataset_squish(metadata$source_name)), '</p>\n',
    contributor_badge,
    '<p class="dataset-hero-summary">', dataset_html_escape(dataset_squish(metadata$unit)), '</p>\n',
    '<div class="dataset-hero-actions">',
    '<a class="dataset-button no-external" href="#r-en-action">Voir les résultats R</a>',
    source_button,
    '</div>\n',
    '</div>\n',
    '<div class="dataset-hero-media"><img src="', dataset_html_escape(dataset_image_src(metadata, ctx)), '" alt="Illustration du jeu de données ', dataset_html_escape(dataset_squish(metadata$title)), '"></div>\n',
    '</div>\n',
    '<div class="dataset-overview-grid">\n',
    '<div class="dataset-fact"><span>Territoire</span><strong>', dataset_html_escape(dataset_squish(metadata$geography)), '</strong></div>\n',
    '<div class="dataset-fact"><span>Niveau</span><strong>', dataset_html_escape(dataset_squish(metadata$level)), '</strong></div>\n',
    '<div class="dataset-fact"><span>Structure</span><strong>', dataset_html_escape(dataset_squish(metadata$data_type)), '</strong></div>\n',
    '<div class="dataset-fact"><span>Format</span><strong>', dataset_html_escape(dataset_squish(metadata$format)), '</strong></div>\n',
    '</div>\n',
    '<div class="dataset-pedagogy-band">\n',
    '<div class="dataset-pedagogy-main"><span>Question de départ</span><p>', dataset_html_escape(projects[[1]]), '</p></div>\n',
    '<div class="dataset-score-box"><span>Potentiel pédagogique</span><strong>', dataset_html_escape(score_label), '</strong><div class="dataset-score-track">', dataset_score_segments(score), '</div></div>\n',
    '</div>\n',
    '<div class="dataset-chip-strip">', concept_chips, '</div>\n',
    '<section class="dataset-r-lab" id="r-en-action">\n',
    '<div class="dataset-section-heading"><span>R en action</span><h2>Aperçu reproductible</h2><p>', data_note, '</p></div>\n',
    '<div class="dataset-r-grid">\n',
    '<div class="dataset-code-card"><div class="dataset-card-label">Code minimal</div><pre><code class="language-r">', dataset_html_escape(dataset_r_code(metadata, ctx, csv_path)), '</code></pre></div>\n',
    '<div class="dataset-result-card"><div class="dataset-card-label">Résultats R</div><div class="dataset-r-stats">', dataset_result_stats(preview, metadata, csv_path, ctx$root), '</div>', result_table, '</div>\n',
    '<div class="dataset-chart-card"><div class="dataset-card-label">Lecture statistique</div>', dataset_chart_svg(preview, metadata), '</div>\n',
    '</div>\n',
    '</section>\n',
    '<section class="dataset-teaching-panel">\n',
    '<div><span>Mini-projets</span><ul>', project_items, '</ul></div>\n',
    '<div><span>Activités liées</span><div class="dataset-activity-grid">', activities, '</div></div>\n',
    '</section>\n',
    '<div class="dataset-detail-content">\n',
    sep = ""
  )

  invisible(NULL)
}

render_dataset_detail_footer <- function() {
  cat('</div>\n</section>\n')
  invisible(NULL)
}
