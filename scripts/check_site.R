# Verify the generated artifact, including every internal link and download.
source('R/utils_site_validation.R')
validate_rendered_headings('docs')
root <- normalizePath('docs')
pages <- list.files(root, pattern = '[.]html$', recursive = TRUE, full.names = TRUE)
documents <- setNames(lapply(pages, xml2::read_html), pages)
errors <- character()
search_index <- jsonlite::read_json(file.path(root, 'search.json'))
indexed_pages <- unique(vapply(search_index, function(entry) sub('[?#].*$', '', entry$href), character(1)))
relative_pages <- substring(pages, nchar(root) + 2L)
if (!all(relative_pages %in% indexed_pages)) errors <- c(errors, 'Certaines pages sont absentes de la recherche générale.')
for (page in pages) {
  doc <- documents[[page]]
  first_link <- xml2::xml_find_first(doc, '(//body//a)[1]')
  if (xml2::xml_attr(first_link, 'class') != 'skip-to-content') errors <- c(errors, paste(page, 'lien de contournement absent en première position.'))
  if (length(xml2::xml_find_all(doc, '//main')) != 1L) errors <- c(errors, paste(page, 'doit avoir un main unique.'))
  if (length(xml2::xml_find_all(doc, '//img[not(@alt)]'))) errors <- c(errors, paste(page, 'image sans attribut alt.'))
  ids <- xml2::xml_attr(xml2::xml_find_all(doc, '//*[@id]'), 'id')
  if (anyDuplicated(ids)) errors <- c(errors, paste(page, 'identifiants HTML dupliqués.'))
  links <- unique(c(xml2::xml_attr(xml2::xml_find_all(doc, '//*[@href]'), 'href'),
                    xml2::xml_attr(xml2::xml_find_all(doc, '//img[@src]|//script[@src]'), 'src')))
  for (link in links[!is.na(links) & nzchar(links)]) {
    if (grepl('^([A-Za-z][A-Za-z0-9+.-]*:|//)', link)) next
    parts <- strsplit(link, '#', fixed = TRUE)[[1]]
    target <- utils::URLdecode(sub('[?].*$', '', parts[[1]]))
    if (startsWith(target, '/donnees-bleues/')) target <- substring(target, nchar('/donnees-bleues/') + 1L)
    candidate <- if (!nzchar(target)) page else if (startsWith(link, '/')) file.path(root, sub('^/', '', target)) else file.path(dirname(page), target)
    if (dir.exists(candidate)) candidate <- file.path(candidate, 'index.html')
    candidate <- normalizePath(candidate, mustWork = FALSE)
    if (!file.exists(candidate)) {errors <- c(errors, paste(page, 'lien absent :', link)); next}
    if (length(parts) > 1L && nzchar(parts[[2]]) && grepl('[.]html$', candidate)) {
      destination <- documents[[candidate]]
      if (is.null(destination)) destination <- xml2::read_html(candidate)
      anchors <- c(xml2::xml_attr(xml2::xml_find_all(destination, '//*[@id]'), 'id'),
                   xml2::xml_attr(xml2::xml_find_all(destination, '//a[@name]'), 'name'))
      if (!utils::URLdecode(parts[[2]]) %in% anchors) errors <- c(errors, paste(page, 'ancre absente :', link))
    }
  }
}
# Vérifier les références complètes, après la typographie automatique de Quarto.
source('R/utils_donnees_quebec.R')
registry <- dq_read_registry()
dq_validate_registry(registry)
normalize_citation <- function(x) trimws(gsub('[[:space:]]+', ' ', chartr('’‘“”', '\'\'""', x)))
citation_pages <- 0L
for (page in pages) {
  relative <- substring(page, nchar(root) + 2L)
  id <- if (startsWith(relative, 'datasets/')) strsplit(relative, '/', fixed = TRUE)[[1]][[2]] else
    if (startsWith(relative, 'resources/')) sub('[.]html$', '', basename(relative)) else
      if (identical(relative, 'demonstrations/01-ilots-chaleur.html')) 'demonstration-ilots-chaleur' else ''
  entries <- dq_sources(id, registry)
  if (!length(entries)) next
  text <- normalize_citation(xml2::xml_text(documents[[page]]))
  for (entry in entries) if (!grepl(normalize_citation(entry$citation), text, fixed = TRUE))
    errors <- c(errors, paste(page, 'citation Données Québec absente :', entry$page_url))
  citation_pages <- citation_pages + 1L
}
cat(citation_pages, 'pages : références Données Québec contrôlées.\n')

# Exact archive and receipt bytes must be the ones that passed the classroom checks.
for (source in list.files('assets/classroom', pattern = '[.]zip([.]json)?$', full.names = TRUE)) {
  dest <- file.path('docs', source)
  if (!file.exists(dest) || digest::digest(file = source, algo = 'sha256') != digest::digest(file = dest, algo = 'sha256')) {
    errors <- c(errors, paste('Archive rendue différente :', source))
  }
}
# Check the rendered identity on every canonical resource page.
source('R/utils_resources.R')
for (item in resource_catalogue()) {
  page <- file.path(root, item$url)
  doc <- documents[[page]]
  identity <- xml2::xml_find_all(doc, paste0('//*[@data-resource-type="', item$type, '"]'))
  dates <- xml2::xml_attr(xml2::xml_find_all(doc, '//main//dl[contains(@class,"resource-dates")]//time'), 'datetime')
  if (startsWith(item$id, 'billet-')) {
    # Un billet porte sa date éditoriale; les dates du répertoire restent dans les métadonnées.
    lines <- readLines(sub('[.]html$', '.qmd', item$url), warn = FALSE, encoding = 'UTF-8')
    borders <- which(trimws(lines) == '---')
    metadata <- yaml::yaml.load(paste(lines[2:(borders[2] - 1L)], collapse = '\n'))
    article_dates <- xml2::xml_attr(xml2::xml_find_all(doc, '//main//*[contains(concat(" ", normalize-space(@class), " "), " news-byline ")]//time'), 'datetime')
    dates_valid <- length(dates) == 0L && identical(article_dates, metadata$date)
  } else {
    dates_valid <- identical(dates, c(item$date_added, item$date_updated))
  }
  title <- xml2::xml_find_all(doc, '//*[contains(concat(" ", normalize-space(@class), " "), " resource-detail-header ")]//h1')
  if (length(identity) != 1L || length(title) != 1L ||
      !dates_valid) {
    errors <- c(errors, paste(item$url, 'en-tête ou dates de ressource incohérents.'))
  }
}
if (length(errors)) stop(paste(unique(errors), collapse = '\n'), call. = FALSE)
source('scripts/check_demonstrations.R', local = TRUE)
source('scripts/check_seo.R', local = TRUE)
cat(length(pages), 'pages : titres, structure, attributs alt, liens, ancres et téléchargements vérifiés.\n')
