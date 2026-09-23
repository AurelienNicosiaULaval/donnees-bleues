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
  ids <- c(donnees = "dataset-search", activite = "activity-search",
           document = "document-search", application = "application-search")
  labels <- c(donnees = "jeux de données", activite = "activités",
              document = "documents", application = "applications")
  stopifnot(kind %in% names(ids))
  id <- unname(ids[[kind]])
  cat('<div class="catalogue-controls"><label class="catalogue-query" for="', id, '">',
      'Rechercher<input id="', id, '" data-query type="search" placeholder="Titre, sujet ou notion" autocomplete="off"></label>',
      '<details class="catalogue-filter-panel" id="',
      switch(kind, donnees = "catalogue-filters", activite = "preparer-un-cours",
             document = "document-filters", application = "application-filters"), '">',
      '<summary>Filtres</summary><div class="catalogue-filter-fields">', sep = '')
  for (filter in filters) catalogue_select(filter$name, filter$label, filter$values)
  cat('</div><button type="button" class="catalogue-close-filters" data-close-filters>Fermer les filtres</button></details>',
      '<button type="button" class="catalogue-reset-link" data-reset>Réinitialiser</button></div>',
      '<div class="catalogue-results-bar"><p data-result-count aria-live="polite">', count, ' ', labels[[kind]], '</p>',
      '<label>Trier par <select data-sort><option value="title">Titre</option>',
      if (kind == "activite") '<option value="duration">Durée</option>' else '',
      '</select></label></div><div class="catalogue-active-filters" data-active-filters aria-label="Filtres appliqués"></div>', sep = '')
}

catalogue_attributes <- function(values) {
  paste0(' data-', names(values), '="', catalogue_escape(values), '"', collapse = '')
}
