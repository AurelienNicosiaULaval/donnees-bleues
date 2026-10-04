# Contrôle du site distribué, exécuté aussi dans GitHub Actions.
source("R/utils_seo.R")
source("R/utils_catalogue.R")
config <- read_yaml("_quarto.yml")
base_url <- config$website[["site-url"]]
root <- normalizePath("docs")
pages <- sort(list.files(root, pattern = "[.]html$", recursive = TRUE))
catalogue <- build_catalogue("datasets")
dataset_pages <- sub("[.]qmd$", ".html", catalogue$fiche)
sitemap <- read_xml(file.path(root, "sitemap.xml"))
urls <- xml_text(xml_find_all(sitemap, '//*[local-name()="loc"]'))
errors <- character()
titles <- descriptions <- canonicals <- character()
indexable <- character()
value <- function(doc, xpath, attribute = "content") xml_attr(xml_find_all(doc, xpath), attribute)
for (path in pages) {
  doc <- read_html(file.path(root, path))
  expected <- seo_url(path, base_url)
  canonical <- value(doc, '//head/link[@rel="canonical"]', "href")
  description <- value(doc, '//head/meta[@name="description"]')
  title <- xml_text(xml_find_all(doc, "//head/title"))
  if (length(canonical) != 1L || canonical != expected) errors <- c(errors, paste(path, "canonical incohérent"))
  if (length(description) != 1L || !nzchar(description)) errors <- c(errors, paste(path, "description absente ou dupliquée"))
  if (length(title) != 1L || !nzchar(title)) errors <- c(errors, paste(path, "titre absent ou dupliqué"))
  editor <- grepl("^outils/[^/]+/edit/index[.]html$", path)
  noindex <- any(grepl("noindex", value(doc, '//meta[@name="robots"]'), ignore.case = TRUE))
  if (editor != noindex) errors <- c(errors, paste(path, "directive robots inattendue"))
  if (!noindex) indexable <- c(indexable, canonical)
  for (key in c("title", "description", "url", "type", "site_name", "locale", "image", "image:alt")) {
    field <- value(doc, paste0('//head/meta[@property="og:', key, '"]'))
    if (length(field) != 1L || !nzchar(field)) errors <- c(errors, paste(path, "Open Graph", key))
  }
  for (key in c("card", "title", "description", "image", "image:alt")) {
    field <- value(doc, paste0('//head/meta[@name="twitter:', key, '"]'))
    if (length(field) != 1L || !nzchar(field)) errors <- c(errors, paste(path, "Twitter Card", key))
  }
  if (!identical(value(doc, '//meta[@property="og:url"]'), canonical)) errors <- c(errors, paste(path, "URL de partage différente"))
  image <- value(doc, '//meta[@property="og:image"]')
  if (length(image) == 1L && (!startsWith(image, base_url) ||
      !file.exists(file.path(root, substring(image, nchar(base_url) + 1L))))) {
    errors <- c(errors, paste(path, "image de partage absente"))
  }
  nodes <- xml_find_all(doc, '//head/script[@id="db-dataset-jsonld"]')
  if (path %in% dataset_pages) {
    if (length(nodes) != 1L) { errors <- c(errors, paste(path, "Dataset absent")); next }
    structured <- fromJSON(xml_text(nodes), simplifyVector = FALSE)
    m <- read_dataset_metadata(file.path("datasets", catalogue$id[match(path, dataset_pages)]))
    if (!identical(structured, seo_dataset(m, expected, root, base_url))) errors <- c(errors, paste(path, "Dataset différent des métadonnées"))
    if (nchar(structured$description) < 50L || nchar(structured$description) > 5000L) errors <- c(errors, paste(path, "longueur du résumé Dataset"))
    for (download in structured$distribution) {
      if (startsWith(download$contentUrl, base_url) && !file.exists(file.path(root,
          substring(download$contentUrl, nchar(base_url) + 1L)))) errors <- c(errors, paste(path, "distribution locale absente"))
    }
  } else if (length(nodes)) errors <- c(errors, paste(path, "Dataset sur une page autre qu'une fiche"))
  titles <- c(titles, title); descriptions <- c(descriptions, description); canonicals <- c(canonicals, canonical)
}
if (anyDuplicated(titles)) errors <- c(errors, "Titres HTML dupliqués.")
if (anyDuplicated(canonicals) || anyDuplicated(urls) || !setequal(urls, indexable)) errors <- c(errors, "Sitemap incomplet ou URL dupliquée.")
if (!all(dataset_pages %in% pages)) errors <- c(errors, "Fiches de données absentes du rendu.")
robots <- readLines(file.path(root, "robots.txt"), warn = FALSE)
if (!paste0("Sitemap: ", base_url, "sitemap.xml") %in% robots || any(grepl("^Disallow: /", robots))) errors <- c(errors, "robots.txt incohérent.")
if (length(errors)) stop(paste(unique(errors), collapse = "\n"), call. = FALSE)
cat(length(pages), "pages,", length(urls), "URL indexables et", length(dataset_pages), "Dataset : titres, descriptions, canonical, partage, distributions, sitemap et robots vérifiés.\n")
