# Shared controls for the data and activity catalogues.
source("R/utils_editorial.R")
source("R/utils_resource_identity.R")

catalogue_escape <- function(value) {
  as.character(htmltools::htmlEscape(as.character(value), attribute = TRUE))
}

catalogue_tokens <- function(values) {
  unique(trimws(unlist(strsplit(paste(values, collapse = ";"), ";", fixed = TRUE))))
}

catalogue_select <- function(name, label, values) {
  values <- sort(unique(values[!is.na(values) & nzchar(values)]))
  cat('<label>', catalogue_escape(label), '<select data-filter="', name, '"><option value="">Tous</option>',
      paste0('<option value="', catalogue_escape(values), '">', catalogue_escape(values), '</option>', collapse = ''),
      '</select></label>', sep = '')
}

catalogue_controls <- function(kind, count, filters) {
  id <- if (kind == "donnees") "dataset-search" else "activity-search"
  cat('<div class="catalogue-controls"><label class="catalogue-query" for="', id, '">',
      'Rechercher<input id="', id, '" data-query type="search" placeholder="Titre, sujet ou notion" autocomplete="off"></label>',
      '<details class="catalogue-filter-panel" id="', if (kind == "donnees") "catalogue-filters" else "preparer-un-cours", '">',
      '<summary>Filtres</summary><div class="catalogue-filter-fields">', sep = '')
  for (filter in filters) catalogue_select(filter$name, filter$label, filter$values)
  cat('</div><button type="button" class="catalogue-close-filters" data-close-filters>Fermer les filtres</button></details>',
      '<button type="button" class="catalogue-reset-link" data-reset>Réinitialiser</button></div>',
      '<div class="catalogue-results-bar"><p data-result-count aria-live="polite">', count,
      if (kind == "donnees") ' jeux de données' else ' activités', '</p>',
      '<label>Trier par <select data-sort><option value="title">Titre</option>',
      if (kind == "activite") '<option value="duration">Durée</option>' else '',
      '</select></label></div><div class="catalogue-active-filters" data-active-filters aria-label="Filtres appliqués"></div>', sep = '')
}

catalogue_attributes <- function(values) {
  paste0(' data-', names(values), '="', catalogue_escape(values), '"', collapse = '')
}
