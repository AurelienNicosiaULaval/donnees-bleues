# Catalogue commun : les métadonnées existantes restent la source de référence.
library(readr)
library(yaml)
library(htmltools)

resource_text <- function(x, fallback = "Non renseigné") {
  x <- as.character(unlist(x, use.names = FALSE))
  x <- x[!is.na(x) & nzchar(trimws(x))]
  if (length(x)) paste(x, collapse = "; ") else fallback
}
resource_escape <- function(x) as.character(htmlEscape(resource_text(x, ""), attribute = TRUE))
resource_url <- function(x) {
  stopifnot(length(x) == 1L, grepl("^https://", x))
  resource_escape(x)
}
resource_extra <- function(root = ".") {
  items <- read_yaml(file.path(root, "data/metadata/ressources.yml"))
  ids <- vapply(items, function(x) x$id, character(1))
  stopifnot(!anyDuplicated(ids), all(grepl("^[a-z0-9-]+$", ids)))
  for (x in items) {
    stopifnot(x$type %in% c("document", "application"), length(x$authors) > 0,
              length(x$themes) > 0, nzchar(x$title), nzchar(x$description))
    resource_url(x$url)
    resource_url(x$evidence_url)
    if (!is.null(x$code_url)) resource_url(x$code_url)
  }
  items
}
resource_catalogue <- function(root = ".") {
  d <- read_csv(file.path(root, "data/metadata/catalogue.csv"), show_col_types = FALSE)
  a <- read_csv(file.path(root, "data/metadata/catalogue_activites.csv"), show_col_types = FALSE)
  dataset_metadata <- lapply(d$id, function(id) read_yaml(file.path(root, "datasets", id, "metadata.yml")))
  result <- lapply(seq_len(nrow(d)), function(i) list(
    id = paste0("donnees-", d$id[i]), type = "donnees", title = d$title[i],
    description = paste(d$unit[i], d$geography[i], sep = ". "),
    themes = d$theme[i], concepts = paste(d$concepts[i], d$search_aliases[i]),
    authors = d$source_name[i], author_label = "Source des données", contributor = d$contributor_name[i],
    courses = dataset_metadata[[i]]$courses, url = sub("[.]qmd$", ".html", d$fiche[i])))
  result <- c(result, lapply(seq_len(nrow(a)), function(i) {
    j <- match(a$dataset_id[i], d$id)
    stopifnot(!is.na(j))
    activity_metadata <- read_yaml(file.path(root, sub("[.]qmd$", ".yml", a$activity_url[i])))
    list(id = a$id[i], type = "activite", title = a$title[i], description = a$question[i],
      themes = d$theme[j], concepts = paste(a$concepts[i], a$search_aliases[i]),
      authors = d$contributor_name[j], author_label = "Contribution pédagogique",
      contributor = d$contributor_name[j], courses = activity_metadata$courses,
      url = sub("[.]qmd$", ".html", a$activity_url[i]))
  }))
  c(result, lapply(resource_extra(root), function(x) {
    x$url <- paste0("resources/", x$id, ".html")
    x
  }))
}
resource_labels <- c(donnees = "Données", activite = "Activités", document = "Documents", application = "Applications")
render_resource_cards <- function() {
  items <- resource_catalogue()
  cat('<div class="resource-grid" id="resource-results">')
  for (x in items) {
    courses <- resource_text(x$courses, "Usage en cours non documenté")
    search <- resource_text(c(x$title, x$description, x$themes, x$concepts, x$authors, x$contributor, x$courses))
    cat('<article class="resource-card" data-type="', x$type, '" data-theme="', resource_escape(x$themes),
      '" data-author="', resource_escape(x$authors), '" data-course="', resource_escape(x$courses),
      '" data-search="', resource_escape(search), '">',
      '<p class="resource-kind">', resource_labels[x$type], ' · ', resource_escape(x$themes), '</p>',
      '<h2><a href="', resource_escape(x$url), '">', resource_escape(x$title), '</a></h2>',
      '<p>', resource_escape(x$description), '</p><dl><dt>',
      if (is.null(x$author_label)) 'Auteur ou autrice' else x$author_label,
      '</dt><dd>', resource_escape(x$authors), '</dd><dt>Contribution au répertoire</dt><dd>',
      resource_escape(x$contributor), '</dd><dt>Cours</dt><dd>', resource_escape(courses),
      '</dd></dl></article>', sep = '')
  }
  cat('</div>')
}
render_resource_detail <- function(id, root = "..") {
  items <- resource_extra(root)
  x <- items[[match(id, vapply(items, function(x) x$id, character(1)))]]
  cat('<p class="resource-kind">', resource_labels[x$type], ' · ', resource_escape(x$format), '</p>',
    '<p class="resource-intro">', resource_escape(x$description), '</p><dl class="resource-attribution">',
    '<dt>Auteur ou autrice</dt><dd>', resource_escape(x$authors), '</dd>',
    '<dt>Contribution au répertoire</dt><dd>', resource_escape(x$contributor), '</dd>',
    '<dt>Thèmes</dt><dd>', resource_escape(x$themes), '</dd>',
    '<dt>Utilisé dans</dt><dd>', resource_escape(resource_text(x$courses, "Usage en cours non documenté")), '</dd>',
    '<dt>Réutilisation</dt><dd>', resource_escape(x$license), '</dd></dl>',
    '<p><a class="dataset-button" href="', resource_url(x$url), '">',
    if (x$type == "application") 'Ouvrir l’application' else 'Lire le document', '</a></p>', sep = '')
  if (!is.null(x$code_url)) cat('<p><a href="', resource_url(x$code_url), '">Consulter le code source</a></p>', sep = '')
  cat('<p>', resource_escape(x$note), '</p>')
  for (dataset in x$related_datasets) {
    stopifnot(grepl("^[a-z0-9-]+$", dataset), file.exists(file.path(root, "datasets", dataset, "metadata.yml")))
    cat('<p><a href="../datasets/', dataset, '/fiche.html">Consulter la fiche de données associée</a></p>', sep = '')
  }
  cat('<p><a href="', resource_url(x$evidence_url), '">Source de la notice</a> · <a href="../ressources.html">Toutes les ressources</a></p>', sep = '')
}
