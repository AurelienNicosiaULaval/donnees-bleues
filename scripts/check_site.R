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
# Exact archive and receipt bytes must be the ones that passed the classroom checks.
for (source in list.files('assets/classroom', pattern = '[.]zip([.]json)?$', full.names = TRUE)) {
  dest <- file.path('docs', source)
  if (!file.exists(dest) || digest::digest(file = source, algo = 'sha256') != digest::digest(file = dest, algo = 'sha256')) {
    errors <- c(errors, paste('Archive rendue différente :', source))
  }
}
if (length(errors)) stop(paste(unique(errors), collapse = '\n'), call. = FALSE)
cat(length(pages), 'pages : titres, structure, attributs alt, liens, ancres et téléchargements vérifiés.\n')
