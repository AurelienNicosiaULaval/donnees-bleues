# Shared labels, dates and accessible visual identity for every resource type.
resource_identity_escape <- function(value) {
  as.character(htmltools::htmlEscape(as.character(value), attribute = TRUE))
}

validate_resource_dates <- function(metadata) {
  if (length(metadata$date_added) != 1L || length(metadata$date_updated) != 1L) {
    stop("Deux dates uniques sont requises : ", metadata$id, call. = FALSE)
  }
  values <- c(metadata$date_added, metadata$date_updated)
  if (length(values) != 2L || anyNA(values) ||
      !all(grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", values))) {
    stop("Dates d’ajout et de mise à jour requises au format AAAA-MM-JJ : ", metadata$id, call. = FALSE)
  }
  dates <- as.Date(values, format = "%Y-%m-%d")
  if (anyNA(dates) || !all(format(dates, "%Y-%m-%d") == values) ||
      dates[2] < dates[1] || any(dates > Sys.Date())) {
    stop("Chronologie de ressource invalide : ", metadata$id, call. = FALSE)
  }
  invisible(TRUE)
}

resource_date_label <- function(value) {
  date <- as.Date(value)
  months <- c("janvier", "février", "mars", "avril", "mai", "juin", "juillet",
              "août", "septembre", "octobre", "novembre", "décembre")
  paste(as.integer(format(date, "%d")), months[as.integer(format(date, "%m"))], format(date, "%Y"))
}

resource_type_badge <- function(type) {
  labels <- c(donnees = "Données", activite = "Activité", document = "Document", application = "Application")
  icons <- c(
    donnees = '<rect x="3" y="4" width="18" height="16" rx="2"/><path d="M3 10h18M9 10v10M15 10v10"/>',
    activite = '<path d="M9 5H6a2 2 0 0 0-2 2v13h16V7a2 2 0 0 0-2-2h-3"/><rect x="9" y="3" width="6" height="4" rx="1"/><path d="m8 13 3 3 5-6"/>',
    document = '<path d="M14 3H5v18h14V8l-5-5Z M14 3v5h5 M8 12h8 M8 16h6"/>',
    application = '<rect x="3" y="3" width="18" height="18" rx="3"/><path d="M3 8h18m-12 3 6 3.5L9 18z"/>')
  if (length(type) != 1L || !type %in% names(labels)) stop("Type de ressource inconnu.", call. = FALSE)
  paste0('<span class="resource-badge resource-badge--', type, '">',
    '<svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false">',
    icons[[type]], '</svg><span>', labels[[type]], '</span></span>')
}

resource_dates_html <- function(metadata, compact = FALSE) {
  validate_resource_dates(metadata)
  values <- c(metadata$date_added, metadata$date_updated)
  labels <- c("Ajout", "Mise à jour")
  rows <- vapply(seq_along(values), function(i) paste0('<div><dt>', labels[i],
    '</dt><dd><time datetime="', values[i], '">', resource_date_label(values[i]), '</time></dd></div>'), character(1))
  paste0('<dl class="resource-dates', if (compact) ' resource-dates--compact' else '',
    '" aria-label="Dates de la fiche dans le répertoire">', paste(rows, collapse = ""), '</dl>')
}

resource_identity_html <- function(metadata, type) {
  paste0('<div class="resource-identity" data-resource-type="', type,
    '" data-resource-id="', resource_identity_escape(metadata$id), '">',
    resource_type_badge(type), resource_dates_html(metadata), '</div>')
}
