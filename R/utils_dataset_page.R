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

dataset_read_activity_items <- function(ctx) {
  activity_files <- list.files(
    ctx$dataset_dir,
    pattern = "^activite-.*[.]yml$",
    full.names = TRUE
  )

  if (length(activity_files) == 0L) {
    return(list())
  }

  lapply(sort(activity_files), yaml::read_yaml)
}

dataset_badge_list <- function(items, class = "dataset-chip", max_items = 6L) {
  items <- head(unique(dataset_list(items)), max_items)
  if (length(items) == 0L) {
    return("")
  }

  paste(vapply(items, function(item) {
    paste0('<span class="', class, '">', dataset_html_escape(item), '</span>')
  }, character(1)), collapse = "")
}

dataset_activity_href <- function(item) {
  url <- dataset_squish(item$activity_url, "")
  if (url == "") {
    return("")
  }

  basename(sub("[.]qmd$", ".html", url))
}

dataset_activity_cards <- function(metadata, ctx) {
  activities <- dataset_read_activity_items(ctx)

  if (length(activities) == 0L) {
    return("")
  }

  cards <- vapply(activities, function(item) {
    href <- dataset_activity_href(item)
    tag <- if (href == "") "article" else "a"
    href_attr <- if (href == "") "" else paste0(' href="', dataset_html_escape(href), '"')
    activity_type <- dataset_badge_list(item$activity_type, class = "dataset-activity-chip", max_items = 3L)
    notes <- dataset_squish(item$teacher_notes, "")
    notes_html <- if (notes == "") {
      ""
    } else {
      paste0('<p class="dataset-activity-note">', dataset_html_escape(notes), '</p>')
    }

    paste0(
      '<', tag, ' class="dataset-activity-card"', href_attr, '>',
      '<div class="dataset-activity-meta"><span>', dataset_html_escape(dataset_squish(item$duration, "Activité")), '</span>',
      '<span>', dataset_html_escape(dataset_squish(item$level, dataset_squish(metadata$level))), '</span></div>',
      '<strong>', dataset_html_escape(dataset_squish(item$title, "Activité pédagogique")), '</strong>',
      '<p>', dataset_html_escape(dataset_squish(item$question, "Question à préciser.")), '</p>',
      '<div class="dataset-activity-chips">', activity_type, '</div>',
      notes_html,
      '</', tag, '>'
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

dataset_read_preview <- function(csv_path, n_max = 500L) {
  if (is.na(csv_path) || !file.exists(csv_path)) {
    return(NULL)
  }
  tryCatch({
    data <- utils::read.csv(
      csv_path,
      nrows = n_max,
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
    attr(data, "dataset_preview_n_max") <- n_max
    data
  }, error = function(e) NULL)
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

dataset_preview_table <- function(
  data,
  max_rows = 120L,
  max_cols = 12L,
  table_id = NULL,
  interactive = FALSE
) {
  if (is.null(data) || nrow(data) == 0L || ncol(data) == 0L) {
    return('<p class="dataset-empty-result">Aucun aperçu tabulaire local disponible.</p>')
  }

  data <- as.data.frame(data)
  n_visible_rows <- min(nrow(data), max_rows)
  n_visible_cols <- min(ncol(data), max_cols)
  visible <- data[
    seq_len(n_visible_rows),
    seq_len(n_visible_cols),
    drop = FALSE
  ]

  header <- paste(vapply(seq_along(visible), function(j) {
    label <- dataset_html_escape(names(visible)[[j]])
    if (interactive) {
      paste0(
        '<th><button type="button" class="dataset-sort-button" data-dataset-sort="',
        j - 1L,
        '">',
        label,
        '<span aria-hidden="true"></span></button></th>'
      )
    } else {
      paste0("<th>", label, "</th>")
    }
  }, character(1)), collapse = "")

  rows <- vapply(seq_len(nrow(visible)), function(i) {
    values <- vapply(visible[i, , drop = TRUE], function(value) {
      value <- dataset_squish(value, "")
      if (nchar(value) > 80L) paste0(substr(value, 1, 77), "...") else value
    }, character(1))
    paste0("<tr><td>", paste(dataset_html_escape(values), collapse = "</td><td>"), "</td></tr>")
  }, character(1))

  limit_notes <- character()
  if (nrow(data) > nrow(visible)) {
    limit_notes <- c(
      limit_notes,
      paste0(
        "aperçu limité aux ",
        format(nrow(visible), big.mark = " ", scientific = FALSE),
        " premières lignes lues"
      )
    )
  }
  if (ncol(data) > ncol(visible)) {
    limit_notes <- c(
      limit_notes,
      paste0(
        "aperçu limité aux ",
        format(ncol(visible), big.mark = " ", scientific = FALSE),
        " premières colonnes"
      )
    )
  }
  limit_note <- if (length(limit_notes) == 0L) {
    ""
  } else {
    paste0('<p class="dataset-table-note">', dataset_html_escape(paste(limit_notes, collapse = "; ")), '.</p>')
  }

  table_html <- paste0(
    '<div class="dataset-result-table-wrap"><table class="dataset-result-table">',
    '<thead><tr>', header, '</tr></thead>',
    '<tbody>', paste(rows, collapse = ""), '</tbody>',
    '</table></div>',
    limit_note
  )

  if (!interactive) {
    return(table_html)
  }

  table_id <- dataset_squish(table_id, "dataset-interactive-table")

  paste0(
    '<div class="dataset-datatable" id="', dataset_html_escape(table_id), '">',
    '<div class="dataset-datatable-toolbar">',
    '<label><span>Recherche</span><input type="search" data-dataset-search placeholder="Filtrer"></label>',
    '<label><span>Lignes</span><select data-dataset-page-size>',
    '<option value="10">10</option>',
    '<option value="25">25</option>',
    '<option value="50">50</option>',
    '<option value="100">100</option>',
    '</select></label>',
    '<span class="dataset-datatable-count" data-dataset-count></span>',
    '</div>',
    table_html,
    '<div class="dataset-datatable-pager">',
    '<button type="button" data-dataset-prev>Précédent</button>',
    '<span data-dataset-page></span>',
    '<button type="button" data-dataset-next>Suivant</button>',
    '</div>',
    '</div>'
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
      "Lignes dans l'aperçu" = format(nrow(data), big.mark = " ", scientific = FALSE),
      "Lignes déclarées" = dataset_squish(metadata$n_rows),
      "Colonnes dans le CSV" = format(ncol(data), big.mark = " ", scientific = FALSE),
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

dataset_datatable_script <- function() {
  paste(
    "<script>",
    "(function() {",
    "  function normalize(value) {",
    "    return (value || '').toString().toLocaleLowerCase('fr-CA');",
    "  }",
    "  function numericValue(value) {",
    "    var cleaned = (value || '').toString().replace(/\\s/g, '').replace(',', '.');",
    "    if (!/^[-+]?\\d*(\\.\\d+)?$/.test(cleaned) || cleaned === '' || cleaned === '-' || cleaned === '+') {",
    "      return null;",
    "    }",
    "    var parsed = Number(cleaned);",
    "    return Number.isFinite(parsed) ? parsed : null;",
    "  }",
    "  function initDatatable(root) {",
    "    if (root.dataset.enhanced === 'true') return;",
    "    root.dataset.enhanced = 'true';",
    "    var table = root.querySelector('table');",
    "    var tbody = root.querySelector('tbody');",
    "    if (!table || !tbody) return;",
    "    var rows = Array.from(tbody.querySelectorAll('tr'));",
    "    var search = root.querySelector('[data-dataset-search]');",
    "    var pageSize = root.querySelector('[data-dataset-page-size]');",
    "    var count = root.querySelector('[data-dataset-count]');",
    "    var page = root.querySelector('[data-dataset-page]');",
    "    var prev = root.querySelector('[data-dataset-prev]');",
    "    var next = root.querySelector('[data-dataset-next]');",
    "    var sortButtons = Array.from(root.querySelectorAll('[data-dataset-sort]'));",
    "    var state = { query: '', size: 10, page: 1, sortCol: null, sortDir: 1 };",
    "    function filteredRows() {",
    "      var query = normalize(state.query);",
    "      var filtered = query === '' ? rows.slice() : rows.filter(function(row) {",
    "        return normalize(row.textContent).indexOf(query) !== -1;",
    "      });",
    "      if (state.sortCol !== null) {",
    "        filtered.sort(function(a, b) {",
    "          var av = a.children[state.sortCol] ? a.children[state.sortCol].textContent.trim() : '';",
    "          var bv = b.children[state.sortCol] ? b.children[state.sortCol].textContent.trim() : '';",
    "          var an = numericValue(av);",
    "          var bn = numericValue(bv);",
    "          var result;",
    "          if (an !== null && bn !== null) {",
    "            result = an - bn;",
    "          } else {",
    "            result = normalize(av).localeCompare(normalize(bv), 'fr-CA', { numeric: true });",
    "          }",
    "          return result * state.sortDir;",
    "        });",
    "      }",
    "      return filtered;",
    "    }",
    "    function render() {",
    "      var filtered = filteredRows();",
    "      var totalPages = Math.max(1, Math.ceil(filtered.length / state.size));",
    "      state.page = Math.min(Math.max(1, state.page), totalPages);",
    "      var start = (state.page - 1) * state.size;",
    "      var visible = filtered.slice(start, start + state.size);",
    "      filtered.forEach(function(row) { tbody.appendChild(row); });",
    "      rows.filter(function(row) { return filtered.indexOf(row) === -1; }).forEach(function(row) { tbody.appendChild(row); });",
    "      rows.forEach(function(row) { row.hidden = true; });",
    "      visible.forEach(function(row) { row.hidden = false; });",
    "      if (count) count.textContent = filtered.length + ' ligne' + (filtered.length > 1 ? 's' : '');",
    "      if (page) page.textContent = 'Page ' + state.page + ' / ' + totalPages;",
    "      if (prev) prev.disabled = state.page <= 1;",
    "      if (next) next.disabled = state.page >= totalPages;",
    "      sortButtons.forEach(function(button) {",
    "        var indicator = button.querySelector('span');",
    "        if (!indicator) return;",
    "        var col = Number(button.dataset.datasetSort);",
    "        indicator.textContent = col === state.sortCol ? (state.sortDir === 1 ? ' ↑' : ' ↓') : '';",
    "      });",
    "    }",
    "    if (search) {",
    "      search.addEventListener('input', function(event) {",
    "        state.query = event.target.value;",
    "        state.page = 1;",
    "        render();",
    "      });",
    "    }",
    "    if (pageSize) {",
    "      state.size = Number(pageSize.value) || 10;",
    "      pageSize.addEventListener('change', function(event) {",
    "        state.size = Number(event.target.value) || 10;",
    "        state.page = 1;",
    "        render();",
    "      });",
    "    }",
    "    if (prev) prev.addEventListener('click', function() { state.page -= 1; render(); });",
    "    if (next) next.addEventListener('click', function() { state.page += 1; render(); });",
    "    sortButtons.forEach(function(button) {",
    "      button.addEventListener('click', function() {",
    "        var col = Number(button.dataset.datasetSort);",
    "        if (state.sortCol === col) {",
    "          state.sortDir = state.sortDir * -1;",
    "        } else {",
    "          state.sortCol = col;",
    "          state.sortDir = 1;",
    "        }",
    "        state.page = 1;",
    "        render();",
    "      });",
    "    });",
    "    render();",
    "  }",
    "  function initDocumentationPanel() {",
    "    var panel = document.getElementById('documentation');",
    "    if (!panel) return;",
    "    function openForHash() {",
    "      if (!window.location.hash) return;",
    "      var id = window.location.hash.slice(1);",
    "      if (id === 'documentation') {",
    "        panel.open = true;",
    "        return;",
    "      }",
    "      var target = document.getElementById(id);",
    "      if (target && panel.contains(target)) panel.open = true;",
    "    }",
    "    window.addEventListener('hashchange', openForHash);",
    "    openForHash();",
    "  }",
    "  function initAll() {",
    "    initDocumentationPanel();",
    "    document.querySelectorAll('.dataset-datatable').forEach(initDatatable);",
    "  }",
    "  if (document.readyState === 'loading') {",
    "    document.addEventListener('DOMContentLoaded', initAll);",
    "  } else {",
    "    initAll();",
    "  }",
    "})();",
    "</script>",
    sep = "\n"
  )
}

dataset_metadata_table <- function(metadata, table_id = NULL, interactive = FALSE) {
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
  dataset_preview_table(
    data,
    max_rows = 5L,
    max_cols = 2L,
    table_id = table_id,
    interactive = interactive
  )
}

render_dataset_minimal_result <- function() {
  ctx <- dataset_current_context()
  metadata <- dataset_read_metadata(ctx$dataset_dir)
  csv_path <- dataset_processed_csv(metadata, ctx)
  preview <- dataset_read_preview(csv_path)

  if (!is.null(preview)) {
    data_note <- paste0(
      "Sortie calculée par R à partir de ",
      dataset_html_escape(dataset_relative_path(csv_path, ctx$root)),
      "."
    )
    result_table <- dataset_preview_table(
      preview,
      max_rows = 120L,
      max_cols = 10L,
      table_id = "dataset-code-result-table",
      interactive = TRUE
    )
  } else {
    data_note <- "Aucune table préparée locale n'est disponible pour exécuter un aperçu tabulaire fiable."
    result_table <- dataset_metadata_table(
      metadata,
      table_id = "dataset-code-result-table",
      interactive = TRUE
    )
  }

  cat(
    '<div class="dataset-minimal-result">',
    '<div class="dataset-card-label">Résultat visible</div>',
    '<p>', data_note, ' Les exemples qui téléchargent une source externe restent non évalués pendant le rendu du site afin de garder les fiches stables.</p>',
    '<div class="dataset-r-stats">', dataset_result_stats(preview, metadata, csv_path, ctx$root), '</div>',
    result_table,
    '</div>',
    sep = ""
  )

  invisible(NULL)
}

render_dataset_detail_header <- function() {
  ctx <- dataset_current_context()
  metadata <- dataset_read_metadata(ctx$dataset_dir)
  csv_path <- dataset_processed_csv(metadata, ctx)
  preview <- dataset_read_preview(csv_path)
  activities <- dataset_read_activity_items(ctx)
  featured_activity <- if (length(activities) > 0L) activities[[1L]] else list()
  projects <- dataset_list(metadata$idees_mini_projets)
  if (length(projects) == 0L) {
    projects <- paste0("Explorer ", tolower(dataset_squish(metadata$theme, "ce jeu de données")), " avec une question descriptive.")
  }
  concepts <- unique(c(dataset_list(featured_activity$concepts), dataset_list(metadata$concepts)))
  variables <- dataset_list(metadata$variables_principales)
  featured_title <- dataset_squish(featured_activity$title, "Activité de départ")
  featured_question <- dataset_squish(featured_activity$question, projects[[1]])
  featured_duration <- dataset_squish(featured_activity$duration, "Durée à préciser")
  featured_level <- dataset_squish(featured_activity$level, dataset_squish(metadata$level))
  featured_type <- dataset_badge_list(featured_activity$activity_type, class = "dataset-activity-chip", max_items = 3L)
  teaching_note <- dataset_squish(featured_activity$teacher_notes, dataset_squish(metadata$notes, "Je ne sais pas."))
  source_url <- dataset_squish(metadata$source_url, "")
  contributor_badge <- dataset_contributor_badge(metadata)
  source_name <- dataset_squish(metadata$source_name)
  source_html <- if (source_url == "") {
    dataset_html_escape(source_name)
  } else {
    paste0('<a href="', dataset_html_escape(source_url), '">', dataset_html_escape(source_name), '</a>')
  }
  fact_items <- paste(
    paste0(
      '<div class="dataset-simple-fact"><span>Territoire</span><strong>',
      dataset_html_escape(dataset_squish(metadata$geography)),
      '</strong></div>'
    ),
    paste0(
      '<div class="dataset-simple-fact"><span>Niveau</span><strong>',
      dataset_html_escape(dataset_squish(metadata$level)),
      '</strong></div>'
    ),
    paste0(
      '<div class="dataset-simple-fact"><span>Format</span><strong>',
      dataset_html_escape(dataset_squish(metadata$format)),
      '</strong></div>'
    ),
    sep = ""
  )
  source_meta <- paste0(
    '<div class="dataset-source-strip">',
    '<span>Source : ', source_html, '</span>',
    '<span>Licence : ', dataset_html_escape(dataset_squish(metadata$license)), '</span>',
    '<span>Téléchargé : ', dataset_html_escape(dataset_squish(metadata$access_date)), '</span>',
    '</div>'
  )
  project_items <- paste(vapply(head(projects, 3L), function(item) {
    paste0('<li>', dataset_html_escape(item), '</li>')
  }, character(1)), collapse = "")
  concept_badges <- dataset_badge_list(concepts, max_items = 6L)
  variable_badges <- dataset_badge_list(variables, class = "dataset-variable-chip", max_items = 7L)
  if (variable_badges == "") {
    variable_badges <- '<span class="dataset-variable-chip">Variables à préciser</span>'
  }
  concept_summary <- dataset_collapse(head(concepts, 4L), sep = ", ")
  if (concept_summary == "") {
    concept_summary <- dataset_squish(metadata$theme, "un thème à préciser")
  }
  why_text <- paste0(
    "Pour travailler ",
    dataset_html_escape(concept_summary),
    " à partir d'un contexte ",
    dataset_html_escape(tolower(dataset_squish(metadata$theme, "québécois"))),
    " lié à ",
    dataset_html_escape(dataset_squish(metadata$geography)),
    "."
  )

  result_table <- if (!is.null(preview)) {
    dataset_preview_table(
      preview,
      max_rows = 120L,
      max_cols = 10L,
      table_id = "dataset-header-result-table",
      interactive = TRUE
    )
  } else {
    dataset_metadata_table(
      metadata,
      table_id = "dataset-header-result-table",
      interactive = TRUE
    )
  }
  data_note <- if (!is.na(csv_path) && file.exists(csv_path)) {
    paste0("Aperçu calculé par R à partir de ", dataset_html_escape(dataset_relative_path(csv_path, ctx$root)), ".")
  } else {
    "Aperçu léger calculé par R à partir des métadonnées vérifiées afin de garder la fiche rapide et stable au rendu."
  }

  cat(
    '<section class="dataset-detail-page">\n',
    '<section class="dataset-teacher-hero">\n',
    '<div class="dataset-hero-copy">\n',
    '<nav class="dataset-breadcrumb"><a href="', ctx$relative_root, '/catalogue.html">Catalogue</a><span>/</span><span>',
    dataset_html_escape(dataset_squish(metadata$theme)), '</span></nav>\n',
    '<h1>', dataset_html_escape(dataset_squish(metadata$title, "Jeu de données")), '</h1>\n',
    '<p class="dataset-teacher-question">', dataset_html_escape(featured_question), '</p>\n',
    contributor_badge,
    source_meta,
    '<div class="dataset-hero-actions">',
    '<a class="dataset-button no-external" href="#apercu-interactif">Voir les données</a>',
    '<a class="dataset-button secondary no-external" href="#activites-pedagogiques">Activités</a>',
    '</div>\n',
    '</div>\n',
    '<aside class="dataset-featured-activity">\n',
    '<span class="dataset-panel-label">Activité prête à lancer</span>\n',
    '<h2>', dataset_html_escape(featured_title), '</h2>\n',
    '<p>', dataset_html_escape(featured_question), '</p>\n',
    '<div class="dataset-featured-meta"><span>', dataset_html_escape(featured_duration), '</span><span>', dataset_html_escape(featured_level), '</span></div>\n',
    '<div class="dataset-activity-chips">', featured_type, '</div>\n',
    '</aside>\n',
    '</section>\n',
    '<section class="dataset-teacher-plan">\n',
    '<article><span class="dataset-panel-label">Pourquoi l’utiliser?</span><p>', why_text, '</p><div class="dataset-chip-row">', concept_badges, '</div></article>\n',
    '<article><span class="dataset-panel-label">Ce que les étudiantes et étudiants font</span><ul>', project_items, '</ul></article>\n',
    '<article><span class="dataset-panel-label">À cadrer en classe</span><p>', dataset_html_escape(teaching_note), '</p></article>\n',
    '</section>\n',
    '<section class="dataset-r-lab" id="apercu-interactif">\n',
    '<div class="dataset-section-heading"><span>Aperçu des données</span><h2>Entrer par les lignes, puis poser une question</h2><p>', data_note, '</p></div>\n',
    '<div class="dataset-preview-layout">',
    '<div class="dataset-result-card"><div class="dataset-card-label">Table consultable</div>', result_table, '</div>\n',
    '<aside class="dataset-variable-panel"><span class="dataset-panel-label">Variables à repérer</span><div class="dataset-variable-list">', variable_badges, '</div><div class="dataset-simple-facts">', fact_items, '</div></aside>\n',
    '</div>',
    '</section>\n',
    '<details class="dataset-doc-panel" id="documentation">\n',
    '<summary><span>Documentation complète</span><strong>Sources, variables, code R minimal, méthode et limites</strong></summary>\n',
    '<div class="dataset-detail-content">\n',
    sep = ""
  )

  invisible(NULL)
}

render_dataset_detail_footer <- function() {
  ctx <- dataset_current_context()
  metadata <- dataset_read_metadata(ctx$dataset_dir)
  activities <- dataset_activity_cards(metadata, ctx)
  activity_section <- if (activities == "") {
    ""
  } else {
    paste0(
      '<section class="dataset-activities-panel" id="activites-pedagogiques">',
      '<div class="dataset-section-heading"><span>Activités pédagogiques</span><h2>Pour aller plus loin</h2></div>',
      '<div class="dataset-activity-grid">', activities, '</div>',
      '</section>\n'
    )
  }

  cat('</div>\n</details>\n', activity_section, '</section>\n', dataset_datatable_script(), "\n", sep = "")
  invisible(NULL)
}
