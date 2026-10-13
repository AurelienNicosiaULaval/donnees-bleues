# Shared controls for the data and activity catalogues.
source("R/utils_editorial.R")
source("R/utils_resource_identity.R")
source("R/utils_catalogue_filters.R")

catalogue_escape <- function(value) {
  as.character(htmltools::htmlEscape(as.character(value), attribute = TRUE))
}

catalogue_tokens <- function(values) {
  unique(trimws(unlist(strsplit(paste(values, collapse = ";"), ";", fixed = TRUE))))
}

catalogue_select <- function(name, label, values, help = NULL, kind = "") {
  values <- values[!is.na(values) & nzchar(values) & !duplicated(values)]
  if (is.null(names(values))) values <- setNames(values, values)
  id <- paste(kind, name, sep = "-")
  cat('<label for="', id, '">', catalogue_escape(label), '<select id="', id,
      '" data-filter="', name, '" aria-label="', catalogue_escape(label), '"', if (!is.null(help)) paste0(' aria-describedby="', id, '-help"') else '',
      '><option value="">Tous</option>',
      paste0('<option value="', catalogue_escape(unname(values)), '">', catalogue_escape(names(values)), '</option>', collapse = ''),
      '</select>', if (!is.null(help)) paste0('<span class="catalogue-filter-help" id="', id, '-help">', catalogue_escape(help), '</span>') else '',
      '</label>', sep = '')
}

catalogue_controls <- function(kind, count, filters) {
  ids <- c(donnees = "dataset-search", activite = "activity-search", document = "document-search",
           application = "application-search", ressource = "resource-query")
  panels <- c(donnees = "catalogue-filters", activite = "preparer-un-cours", document = "document-filters",
              application = "application-filters", ressource = "resource-filters")
  stopifnot(kind %in% names(ids))
  id <- unname(ids[[kind]])
  cat('<div class="catalogue-controls"><label class="catalogue-query" for="', id, '">',
      'Rechercher<input id="', id, '" data-query type="search" placeholder="Titre, notion, lieu, auteur ou cours" autocomplete="off"></label>',
      '<label class="catalogue-sort" for="', kind, '-sort">Trier par<select id="', kind,
      '-sort" data-sort><option value="added">Ajouts récents</option><option value="updated">Mises à jour récentes</option>',
      '<option value="title">Titre A à Z</option><option value="title-desc">Titre Z à A</option>',
      if (kind == "activite") '<option value="duration">Durée croissante</option><option value="duration-desc">Durée décroissante</option>' else '',
      '</select></label><details class="catalogue-filter-panel" id="', panels[[kind]], '" open>',
      '<summary>Affiner les résultats</summary><div class="catalogue-filter-fields">', sep = '')
  for (filter in filters) catalogue_select(filter$name, filter$label, filter$values, filter$help, kind)
  cat('</div></details></div><div class="catalogue-results-bar"><p data-result-count role="status" aria-live="polite">',
      count, ' ressources</p><button type="button" class="catalogue-reset-link" data-reset>Réinitialiser</button></div>',
      '<div class="catalogue-active-filters" data-active-filters aria-label="Filtres appliqués"></div>', sep = '')
}

catalogue_attributes <- function(values) {
  paste0(' data-', names(values), '="', catalogue_escape(values), '"', collapse = '')
}
