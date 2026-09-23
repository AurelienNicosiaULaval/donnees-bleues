source(if (file.exists("R/utils_editorial.R")) "R/utils_editorial.R" else "../../R/utils_editorial.R")
source(if (file.exists("R/utils_resource_identity.R")) "R/utils_resource_identity.R" else "../../R/utils_resource_identity.R")
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
  candidates <- file.path(ctx$root, "assets", "cards", paste0(id, c(".webp", ".jpg", ".jpeg", ".png")))
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

dataset_activity_status_label <- function(item) {
  access_mode <- dataset_squish(item$access_mode, "")
  switch(
    access_mode,
    frozen = "Fichiers inclus",
    documentation = "Documentation incluse",
    source_required = "Acquisition préalable",
    ""
  )
}

dataset_activity_cards <- function(metadata, ctx) {
  activities <- dataset_read_activity_items(ctx)

  if (length(activities) == 0L) {
    return("")
  }

  cards <- vapply(activities, function(item) {
    href <- dataset_activity_href(item)
    href_attr <- if (href == "") "" else paste0(' href="', dataset_html_escape(href), '"')
    status_label <- dataset_activity_status_label(item)
    status_html <- if (status_label == "") {
      ""
    } else {
      paste0('<span class="dataset-activity-status">', dataset_html_escape(status_label), '</span>')
    }
    output <- dataset_squish(item$expected_output, "")
    output_html <- if (output == "") {
      ""
    } else {
      paste0('<p class="dataset-activity-output">À produire : ', dataset_html_escape(output), '</p>')
    }

    paste0(
      '<article class="dataset-activity-card">',
      resource_type_badge("activite"),
      '<div class="dataset-activity-meta"><span>', dataset_html_escape(dataset_squish(item$duration, "Activité")), '</span>',
      '<span>', dataset_html_escape(dataset_squish(item$level, dataset_squish(metadata$level))), '</span>',
      status_html,
      '</div>',
      '<h3>', if (nzchar(href)) paste0('<a', href_attr, '>') else '',
      dataset_html_escape(dataset_squish(item$title, "Activité pédagogique")),
      if (nzchar(href)) '</a>' else '', '</h3>',
      '<p>', dataset_html_escape(dataset_squish(item$question, "Question à préciser.")), '</p>',
      '<p class="dataset-activity-prerequisites">Prérequis : ', dataset_html_escape(editorial_sentences(item$prerequisites)), '</p>',
      output_html,
      '</article>'
    )
  }, character(1))

  paste(cards, collapse = "\n")
}

dataset_contributor_badge <- function(metadata) {
  name <- dataset_squish(metadata$contributor_name, "")
  if (name == "") {
    return("")
  }

  role <- dataset_squish(metadata$contributor_role, "")
  role_html <- if (role == "") "" else paste0("<small>", dataset_html_escape(role), "</small>")

  paste0(
    '<div class="dataset-contributor-badge">',
    '<span>Contribution à la fiche</span>',
    "<strong>", dataset_html_escape(name), "</strong>",
    role_html,
    paste0("<small>Cours : ", dataset_html_escape(if (length(metadata$courses)) paste(unlist(metadata$courses), collapse = "; ") else "usage non documenté"), "</small>"),
    "</div>"
  )
}

dataset_processed_csv <- function(metadata, ctx) {
  if (!isTRUE(metadata$publication$preview)) return(NA_character_)

  id <- dataset_squish(metadata$id, basename(ctx$dataset_dir))
  preview_declared <- dataset_squish(
    metadata$preview_file,
    file.path("assets", "previews", paste0(id, ".csv"))
  )
  preview_path <- file.path(ctx$root, preview_declared)
  if (file.exists(preview_path)) preview_path else NA_character_
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
        '<th scope="col" aria-sort="none"><button type="button" class="dataset-sort-button" data-dataset-sort="',
        j - 1L,
        '">',
        label,
        '<span aria-hidden="true"></span></button></th>'
      )
    } else {
      paste0('<th scope="col">', label, '</th>')
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
    '<div class="dataset-result-table-wrap" tabindex="0" role="region" aria-label="Tableau de données, défilement horizontal"><table class="dataset-result-table">',
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
    '<span class="dataset-datatable-count" data-dataset-count role="status" aria-live="polite"></span>',
    '</div>',
    table_html,
    '<div class="dataset-datatable-pager">',
    '<button type="button" data-dataset-prev>Précédent</button>',
    '<span data-dataset-page aria-live="polite"></span>',
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
      "Lignes de la référence documentaire" = dataset_squish(metadata$n_rows),
      "Colonnes dans le CSV" = format(ncol(data), big.mark = " ", scientific = FALSE),
      "Variables num." = n_num,
      "Valeurs manquantes" = paste0(round(missing_pct, 1), " %"),
      "Aperçu" = source_label
    )
  } else {
    stats <- list(
      "Lignes de la référence documentaire" = dataset_squish(metadata$n_rows),
      "Colonnes de la référence documentaire" = dataset_squish(metadata$n_cols),
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

dataset_chart_svg <- function(data, metadata, ctx) {
  if (!isTRUE(metadata$publication$preview)) return("")
  chart_path <- file.path("assets/charts", paste0(metadata$id, ".svg"))
  if (!file.exists(file.path(ctx$root, chart_path))) stop("Graphique déclaré absent : ", metadata$id, call. = FALSE)
  relative_path <- paste(ctx$relative_root, chart_path, sep = "/")
  # La description des axes et la table de données restent accessibles sans l'image.
  description <- paste(metadata$chart$title, metadata$chart$x_label, metadata$chart$y_label, sep = ". ")
  paste0('<figure class="dataset-chart-figure"><img class="dataset-r-chart" src="',
    dataset_html_escape(relative_path), '" alt="', dataset_html_escape(description),
    '" loading="lazy"><figcaption>', dataset_html_escape(description),
    '. Voir la sélection des lignes et la table consultable de cet extrait.</figcaption></figure>')
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
    "        button.closest('th').setAttribute('aria-sort', col === state.sortCol ? (state.sortDir === 1 ? 'ascending' : 'descending') : 'none');",
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

dataset_preview_unavailable <- function(metadata) {
  source_name <- dataset_squish(metadata$source_name, "la source officielle")
  source_url <- dataset_squish(metadata$source_url, "")
  source_link <- if (source_url == "") {
    dataset_html_escape(source_name)
  } else {
    paste0(
      '<a href="', dataset_html_escape(source_url), '">',
      dataset_html_escape(source_name),
      "</a>"
    )
  }

  paste0(
    '<div class="dataset-preview-unavailable">',
    '<strong>Aperçu tabulaire non publié</strong>',
    '<p>Cette fiche ne contient pas encore d’extrait public de lignes réelles. ',
    'Les métadonnées restent décrites dans la documentation; ',
    'consultez ', source_link, ' pour accéder à la source complète.</p>',
    '</div>'
  )
}

dataset_preview_note <- function(metadata, csv_path, root) {
  note <- dataset_squish(metadata$preview_note, "")
  if (note != "") {
    return(dataset_html_escape(note))
  }

  if (!is.na(csv_path) && file.exists(csv_path)) {
    return(paste0(
      "Extrait public de la table préparée à partir de la source officielle, limité à 120 lignes pour une exploration rapide."
    ))
  }

  "Aucun extrait public de lignes réelles n’est disponible dans cette fiche."
}

render_dataset_minimal_result <- function() {
  # L'aperçu interactif est rendu une seule fois dans l'en-tête de fiche.
  # Les blocs conservés dans les fiches plus bas ne doivent pas répéter ni
  # maquiller des métadonnées comme des observations.
  invisible(NULL)
}

# Read dimensions from the distributed archive receipt, never from an older
# reference analysis or the truncated public preview.
dataset_kit_receipt <- function(metadata, ctx) {
  path <- file.path(ctx$root, 'assets', 'classroom', paste0(metadata$id, '.zip.json'))
  if (file.exists(path)) jsonlite::read_json(path) else NULL
}

dataset_version_html <- function(metadata, receipt) {
  escape <- dataset_html_escape
  if (is.null(receipt)) return('')
  parts <- character()
  if (length(receipt$tables)) {
    table <- receipt$tables[[1L]]
    label <- if (receipt$mode == 'documentation') 'Document principal : ' else if (length(receipt$tables) > 1L) 'Table principale : ' else ''
    parts <- c(parts, paste0(label, format(table$rows, big.mark = ' '), ' lignes, ', length(table$columns), ' variables'))
  }
  if (length(metadata$data_version)) parts <- c(parts, paste('Version fixe', metadata$data_version))
  parts <- c(parts, paste('Trousse préparée le', resource_date_label(substr(receipt$prepared_at_utc, 1, 10))))
  paste0('<p class="dataset-version">', escape(paste(parts, collapse = ' · ')), '</p>')
}

render_dataset_detail_header <- function() {
  ctx <- dataset_current_context()
  metadata <- dataset_read_metadata(ctx$dataset_dir)
  escape <- dataset_html_escape
  receipt <- dataset_kit_receipt(metadata, ctx)
  preview <- dataset_read_preview(dataset_processed_csv(metadata, ctx))
  activities <- dataset_activity_cards(metadata, ctx)
  source_url <- dataset_squish(metadata$source_url, '')
  conditions_url <- dataset_squish(metadata$publication$license_url, source_url)
  license_label <- editorial_license(metadata$license)
  if (license_label %in% c('Licences distinctes selon les fichiers', 'Conditions particulières', 'Réutilisation à valider')) {
    conditions_url <- '#sources-et-contributions'
  }
  download_url <- dataset_squish(metadata$download_url, '')
  archive <- paste0(ctx$relative_root, '/assets/classroom/', metadata$id, '.zip')
  actions <- character()
  if (nzchar(download_url)) actions <- c(actions, paste0('<a class="dataset-button" href="', escape(download_url), '">',
    escape(dataset_squish(metadata$download_label, 'Télécharger les données (CSV)')), '</a>'))
  if (!is.null(receipt)) {
    label <- switch(receipt$mode, frozen = 'Télécharger la trousse (ZIP)',
      documentation = 'Télécharger la trousse documentaire (ZIP)',
      source_required = 'Télécharger les scripts, sans les données (ZIP)')
    actions <- c(actions, paste0('<a class="dataset-button', if (length(actions)) ' secondary' else '', '" href="',
      escape(archive), '" download>', label, '</a>'))
  } else if (!nzchar(download_url)) {
    actions <- c(actions, paste0('<a class="dataset-button" href="', escape(source_url), '">Consulter la source</a>'))
  }
  if (!is.null(preview)) actions <- c(actions, '<a class="dataset-text-action" href="#apercu-interactif">Voir l’aperçu</a>')
  if (nzchar(activities)) actions <- c(actions, '<a class="dataset-text-action" href="#activites-pedagogiques">Activités associées</a>')
  limits <- dataset_list(metadata$essential_limits %||% metadata$notes)
  facts <- c('Une ligne' = dataset_squish(metadata$unit), 'Territoire' = dataset_squish(metadata$geography),
             'Période' = dataset_squish(metadata$observation_period, 'Non documentée'))
  fact_html <- paste0('<div><dt>', escape(names(facts)), '</dt><dd>', escape(facts), '</dd></div>', collapse = '')
  if (length(metadata$table_overview)) {
    fact_html <- paste0('<div style="grid-column:1 / -1"><dt>', escape(names(metadata$table_overview)),
      '</dt><dd>', escape(unlist(metadata$table_overview, use.names = FALSE)), '</dd></div>', collapse = '')
  }
  cat('<section class="dataset-detail-shell dataset-editorial">',
      '<header class="dataset-teacher-hero resource-detail-header">',
      '<nav class="dataset-breadcrumb" aria-label="Fil d’Ariane"><a href="', ctx$relative_root, '/catalogue.html">Données</a></nav>',
      resource_identity_html(metadata, 'donnees', show_dates = FALSE),
      '<h1>', escape(metadata$title), '</h1>',
      '<p class="dataset-summary">', escape(dataset_squish(metadata$summary, 'Description non documentée.')), '</p>',
      dataset_version_html(metadata, receipt),
      '<div class="dataset-hero-actions">', paste(actions, collapse = ''), '</div>',
      '<dl class="dataset-record-facts">', fact_html, '</dl>',
      '<p class="dataset-source-brief">Source : <a href="', escape(source_url), '">',
      escape(paste(editorial_sources(metadata), collapse = '; ')), '</a>. ',
      '<a href="', escape(conditions_url), '">', escape(license_label), '</a>.</p>',
      '</header>', sep = '')
  if (!is.null(receipt) && receipt$mode != 'frozen') {
    note <- switch(receipt$mode,
      documentation = 'Cette trousse contient des documents et un protocole. Elle ne fournit pas les données complètes de la source.',
      source_required = 'Les données ne sont pas incluses. Les obtenir auprès de la source avec le script d’acquisition avant la séance; ses conditions de réutilisation restent applicables.')
    cat('<p class="dataset-access-condition">', note, '</p>')
  }
  if (length(limits)) cat('<section class="dataset-essential-limits" aria-labelledby="limites-essentielles">',
    '<h2 id="limites-essentielles">À savoir avant l’analyse</h2><ul>',
    paste0('<li>', escape(limits), '</li>', collapse = ''), '</ul></section>', sep = '')
  if (!is.null(preview)) {
    csv_path <- dataset_processed_csv(metadata, ctx)
    cat('<section class="dataset-r-lab" id="apercu-interactif"><h2>Aperçu des données</h2>',
      '<p class="dataset-preview-caption">', escape(dataset_squish(metadata$preview_caption,
        paste0(nrow(preview), ' lignes affichées. Le fichier complet est accessible en haut de la fiche.'))), '</p>',
      '<details class="dataset-preview-method"><summary>Colonnes et sélection de l’aperçu</summary><p>',
      dataset_preview_note(metadata, csv_path, ctx$root), '</p></details>',
      '<p class="dataset-scroll-hint">Faire défiler le tableau horizontalement pour voir les autres colonnes.</p>',
      dataset_preview_table(preview, max_rows = 120L, max_cols = 10L, table_id = 'dataset-header-result-table', interactive = TRUE),
      '<details><summary>Graphique de l’aperçu</summary>', dataset_chart_svg(preview, metadata, ctx), '</details>',
      '</section>', sep = '')
  }
  if (nzchar(activities)) cat('<section class="dataset-activities-panel" id="activites-pedagogiques">',
    '<h2>Activités associées</h2><div class="dataset-activity-grid">', activities, '</div></section>', sep = '')
  cat('<details class="dataset-doc-panel" id="documentation"><summary>Variables, préparation et références détaillées</summary>',
      '<div class="dataset-detail-content">', sep = '')
  if (length(metadata$reference_note)) {
    cat('<p class="dataset-reference-note">', escape(metadata$reference_note), '</p>', sep = '')
  } else if (!is.null(receipt) && !length(metadata$data_version) &&
             substr(receipt$prepared_at_utc, 1, 10) > metadata$access_date) {
    cat('<p class="dataset-reference-note">La documentation ci-dessous décrit la source consultée le ',
      escape(resource_date_label(metadata$access_date)),
      '. Les dimensions affichées en haut concernent les fichiers de la trousse préparée le ',
      escape(resource_date_label(substr(receipt$prepared_at_utc, 1, 10))),
      '; cette sélection de fichiers et de colonnes est détaillée dans son relevé de provenance.</p>', sep = '')
  }
  invisible(NULL)
}

render_dataset_detail_footer <- function() {
  ctx <- dataset_current_context()
  metadata <- dataset_read_metadata(ctx$dataset_dir)
  escape <- dataset_html_escape
  receipt <- dataset_kit_receipt(metadata, ctx)
  cat('</div></details><section class="resource-record" id="sources-et-contributions">',
      '<h2>Sources, contribution et réutilisation</h2>',
      '<p>Source : <a href="', escape(metadata$source_url), '">', escape(metadata$source_name), '</a>.</p>',
      '<p>Conditions : ', escape(metadata$license), '</p>',
      '<p>Contribution à la fiche : ', escape(dataset_squish(metadata$contributor_name, 'Non documentée')),
      '. ', escape(dataset_squish(metadata$contributor_role, '')), '.</p>',
      '<p>', escape(editorial_course_label(metadata$courses)), '.</p>',
      '<p>Documentation de la source : ', escape(dataset_squish(metadata$access_date)), '.</p>',
      resource_dates_html(metadata, compact = TRUE), sep = '')
  if (!is.null(receipt)) cat('<p><a href="', ctx$relative_root, '/assets/classroom/', escape(metadata$id),
    '.zip.json">Fichiers, dates et empreintes de la trousse</a></p>', sep = '')
  cat('</section></section>', dataset_datatable_script(), '\n', sep = '')
  invisible(NULL)
}
