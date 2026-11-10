# Citations vérifiées sur les fiches officielles; aucun appel réseau au rendu.
dq_registry_path <- function() {
  candidates <- c('data/metadata/donnees_quebec.json', '../data/metadata/donnees_quebec.json', '../../data/metadata/donnees_quebec.json')
  found <- candidates[file.exists(candidates)]
  if (!length(found)) stop('Registre Données Québec absent.', call. = FALSE)
  found[[1]]
}

dq_read_registry <- function(path = dq_registry_path()) {
  jsonlite::read_json(path, simplifyVector = FALSE)
}

dq_sources <- function(dataset_id, registry = dq_read_registry()) {
  Filter(function(x) dataset_id %in% unlist(x$dataset_ids), registry$sources)
}

dq_citation_records <- function(dataset_id, registry = dq_read_registry()) {
  lapply(dq_sources(dataset_id, registry), function(x)
    x[c('page_url', 'citation', 'verified_at_utc', 'license_title', 'license_url')])
}

dq_escape <- function(x) {
  x <- gsub('&', '&amp;', x, fixed = TRUE)
  x <- gsub('<', '&lt;', x, fixed = TRUE)
  x <- gsub('>', '&gt;', x, fixed = TRUE)
  gsub('"', '&quot;', x, fixed = TRUE)
}

dq_citations_markdown <- function(dataset_id, registry = dq_read_registry()) {
  entries <- dq_sources(dataset_id, registry)
  if (!length(entries)) return(character())
  lines <- c('## Références Données Québec', '',
    'Citations des fiches officielles consultées à la date indiquée. Cette vérification documentaire ne constitue pas une nouvelle acquisition des données; les dates des fichiers et leurs transformations figurent dans les notices de provenance.', '')
  for (entry in entries) {
    lines <- c(lines, if (identical(entry$status, 'verified')) entry$citation else
      paste0('Citation à vérifier : ', entry$requested_url, '. ', entry$error), '',
      paste0('Licence de la fiche consultée : ', entry$license_title %||dq% 'non vérifiée',
        '. [Fiche officielle](', entry$page_url %||dq% entry$requested_url, ').'), '')
  }
  while (length(lines) && !nzchar(tail(lines, 1L))) lines <- head(lines, -1L)
  lines
}

`%||dq%` <- function(x, y) if (is.null(x) || !length(x) || !nzchar(x[[1]])) y else x

dq_sources_html <- function(dataset_id, relative_root = '../..', registry = dq_read_registry()) {
  entries <- dq_sources(dataset_id, registry)
  if (!length(entries)) return('')
  citations <- vapply(entries, function(entry) {
    text <- if (identical(entry$status, 'verified')) entry$citation else
      paste0('Citation à vérifier : ', entry$requested_url)
    paste0('<li><p>', dq_escape(text), '</p><p><a href="',
      dq_escape(entry$page_url %||dq% entry$requested_url), '">Fiche officielle</a>',
      if (!is.null(entry$license_title)) paste0(' · ', dq_escape(entry$license_title)), '</p></li>')
  }, character(1))
  paste0('<section class="dq-references"><h3>Citer les données</h3>',
    '<p>Références des fiches officielles consultées. Les fichiers utilisés restent les instantanés décrits dans la provenance; cette vérification documentaire ne les actualise pas.</p>',
    '<ul>', paste(citations, collapse = ''), '</ul>',
    '<p><a href="', relative_root, '/guide.html#acquerir-par-api">Acquérir les données par API et conserver un instantané</a></p></section>')
}

# L'inventaire inclut les sources d'origine des jeux dérivés et les sources multiples.
dq_inventory <- function(datasets_dir = 'datasets') {
  directories <- sort(list.dirs(datasets_dir, recursive = FALSE, full.names = TRUE))
  rows <- list()
  pattern <- 'https?://(?:www[.])?donneesquebec[.]ca/recherche/(?:fr/)?dataset/[A-Za-z0-9_-]+'
  for (directory in directories) {
    files <- list.files(directory, pattern = '[.](yml|yaml|R|qmd|md)$', full.names = TRUE, recursive = TRUE)
    files <- files[!grepl('/downloads/', files, fixed = TRUE)]
    for (file in files) {
      text <- paste(readLines(file, warn = FALSE, encoding = 'UTF-8'), collapse = '\n')
      urls <- unique(regmatches(text, gregexpr(pattern, text, perl = TRUE))[[1]])
      for (url in urls) rows[[length(rows) + 1L]] <- data.frame(dataset_id = basename(directory),
        requested_id = sub('.*/', '', url), requested_url = url, occurrence = file)
    }
  }
  # Notices de lecture, applications et démonstrations hors du catalogue des jeux.
  extras <- unlist(lapply(c('resources', 'applications', 'publication/demonstrations',
                            'publication/amq-donnees-bleues'), function(directory)
    list.files(directory, pattern = '[.](qmd|R|md)$', recursive = TRUE, full.names = TRUE)))
  for (file in extras) {
    id <- if (startsWith(file, 'resources/')) tools::file_path_sans_ext(basename(file)) else
      if (startsWith(file, 'applications/')) strsplit(file, '/', fixed = TRUE)[[1]][[2]] else
        if (startsWith(file, 'publication/demonstrations/')) 'demonstration-ilots-chaleur' else 'article-amq-donnees-bleues'
    text <- paste(readLines(file, warn = FALSE, encoding = 'UTF-8'), collapse = '\n')
    urls <- unique(regmatches(text, gregexpr(pattern, text, perl = TRUE))[[1]])
    for (url in urls) rows[[length(rows) + 1L]] <- data.frame(dataset_id = id,
      requested_id = sub('.*/', '', url), requested_url = url, occurrence = file)
  }
  if (!length(rows)) return(data.frame())
  unique(do.call(rbind, rows))
}

dq_validate_registry <- function(registry = dq_read_registry(), inventory = dq_inventory()) {
  covered <- unlist(lapply(registry$sources, function(x)
    as.vector(outer(unlist(x$dataset_ids), unlist(x$aliases), paste, sep = '|'))))
  required <- unique(paste(inventory$dataset_id, inventory$requested_id, sep = '|'))
  missing <- setdiff(required, covered)
  if (length(missing)) stop('Sources sans notice Données Québec : ', paste(missing, collapse = ', '), call. = FALSE)
  for (entry in registry$sources) {
    if (!identical(entry$status, 'verified') || is.null(entry$citation) ||
        !grepl('Données Québec', entry$citation, fixed = TRUE) ||
        !grepl(entry$page_url, entry$citation, fixed = TRUE)) {
      stop('Citation officielle non vérifiée : ', entry$requested_url, call. = FALSE)
    }
  }
  invisible(TRUE)
}

dq_resource_options <- function(dataset_id, registry = dq_read_registry()) {
  rows <- list()
  for (entry in dq_sources(dataset_id, registry)) for (resource in entry$resources) {
    rows[[length(rows) + 1L]] <- data.frame(package_id = entry$package_id,
      resource_id = resource$id, name = resource$name %||dq% '', format = resource$format %||dq% '',
      method = if (isTRUE(resource$datastore_active)) 'DataStore API' else 'Ressource repérée par API')
  }
  if (!length(rows)) stop('Aucune source Données Québec déclarée pour ce jeu.', call. = FALSE)
  do.call(rbind, rows)
}

dq_acquire <- function(dataset_id, resource_id, directory = NULL, page_size = 5000L) {
  resources <- dq_resource_options(dataset_id)
  selected <- resources[resources$resource_id == resource_id, , drop = FALSE]
  if (nrow(selected) != 1L) stop('Choisir exactement une ressource de la liste.', call. = FALSE)
  if (is.null(directory)) directory <- file.path('data/raw/api', dataset_id,
    format(Sys.time(), '%Y%m%dT%H%M%SZ', tz = 'UTC'))
  if (dir.exists(directory)) stop('Choisir un nouveau dossier d’acquisition.', call. = FALSE)
  path <- ckan_resource_download(selected$package_id, selected$resource_id, directory, page_size = page_size)
  package <- jsonlite::read_json(file.path(directory, 'package.json'))$result
  page_url <- paste0('https://www.donneesquebec.ca/recherche/dataset/', package$name)
  citation_path <- file.path(directory, 'fiche-officielle.html')
  download_source(page_url, citation_path)
  node <- xml2::xml_find_first(xml2::read_html(citation_path), '//*[@id="citation"]')
  citation <- trimws(gsub('[[:space:]]+', ' ', xml2::xml_text(node)))
  if (is.na(citation) || !nzchar(citation) || !grepl(page_url, citation, fixed = TRUE))
    stop('Données acquises, mais citation officielle non vérifiée; conserver le diagnostic.', call. = FALSE)
  writeLines(c('# Citation de la source acquise', '', citation, '',
    paste0('Licence : ', package$license_title, '. ', package$license_url), '',
    'Les réponses API, les dates et les empreintes sont conservées avec les fichiers. Cette acquisition ne remplace pas les données préparées pour les activités. Les transformations propres au jeu restent à appliquer avant de refaire une analyse.'),
    file.path(directory, 'CITATIONS.md'))
  invisible(path)
}

dq_write_kit_resources <- function(stage, dataset_id) {
  registry <- dq_read_registry()
  entries <- dq_sources(dataset_id, registry)
  if (!length(entries)) return(FALSE)
  dir.create(file.path(stage, 'R'), recursive = TRUE, showWarnings = FALSE)
  dir.create(file.path(stage, 'data/metadata'), recursive = TRUE, showWarnings = FALSE)
  for (file in c('R/utils_donnees_quebec.R', 'R/utils_ckan.R', 'R/utils_downloads.R'))
    if (!file.copy(file, file.path(stage, file), overwrite = TRUE)) stop('Copie impossible : ', file)
  registry$sources <- entries
  jsonlite::write_json(registry, file.path(stage, 'data/metadata/donnees_quebec.json'), pretty = TRUE, auto_unbox = TRUE)
  writeLines(dq_citations_markdown(dataset_id, registry), file.path(stage, 'CITATIONS.md'))
  writeLines(c('# Acquisition facultative avec Internet, depuis la racine du projet extrait.',
    '# Installer au besoin : install.packages(c("jsonlite", "httr2", "readr", "digest", "xml2"))',
    '# Exécuter une première fois pour afficher les ressources, puis renseigner resource_id.',
    '# Les nouvelles sources sont conservées à part; les analyses gardent leurs fichiers figés.',
    'library(jsonlite)', 'library(httr2)', 'library(readr)', 'library(digest)', 'library(xml2)',
    'source("R/utils_downloads.R")', 'source("R/utils_ckan.R")', 'source("R/utils_donnees_quebec.R")',
    paste0('dataset_id <- "', dataset_id, '"'), 'resource_id <- ""',
    'if (!nzchar(resource_id)) {', '  print(dq_resource_options(dataset_id), row.names = FALSE)',
    '} else {', '  fichier <- dq_acquire(dataset_id, resource_id)', '  message("Source acquise : ", fichier)', '}'),
    file.path(stage, 'acquerir-donnees-quebec.R'))
  if (file.exists(file.path(stage, 'app.R'))) {
    html <- dq_sources_html(dataset_id, 'https://donneesbleues.ca', registry)
    literal <- paste(capture.output(dput(html)), collapse = '\n')
    writeLines(c('# Références générées depuis le registre Données Québec.',
      'dq_app_citations <- function(ui) {',
      '  htmltools::tagAppendChild(ui, htmltools::tags$details(',
      '    style = "overflow-wrap:anywhere; margin:1rem; padding:1rem;",',
      '    htmltools::tags$summary("Citer les données"),',
      paste0('    htmltools::HTML(', literal, ')'), '  ))', '}'),
      file.path(stage, 'R/donnees_quebec_citations.R'))
  }
  TRUE
}

dq_kit_paths <- function(include_application = FALSE) {
  c('CITATIONS.md', 'acquerir-donnees-quebec.R', 'R/utils_donnees_quebec.R',
    'R/utils_ckan.R', 'R/utils_downloads.R', 'data/metadata/donnees_quebec.json',
    if (include_application) 'R/donnees_quebec_citations.R')
}

dq_annotate_script <- function(path, dataset_id) {
  lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
  while (length(lines) && !nzchar(trimws(tail(lines, 1L)))) lines <- head(lines, -1L)
  citations <- vapply(dq_sources(dataset_id), function(x) x$citation, character(1))
  writeLines(c('# Références des fiches Données Québec consultées; les dates des données restent celles de leur provenance.',
    paste0('# ', citations), lines), path)
}
