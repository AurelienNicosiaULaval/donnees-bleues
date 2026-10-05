# Métadonnées destinées aux moteurs, sans modifier le corps des pages.
library(yaml)
library(xml2)
library(jsonlite)
library(htmltools)

seo_text <- function(value) {
  values <- as.character(unlist(value, use.names = FALSE))
  values <- values[!is.na(values) & nzchar(trimws(values))]
  trimws(gsub("[[:space:]]+", " ", paste(values, collapse = "; ")))
}

seo_url <- function(path, base_url) {
  if (identical(path, "index.html")) return(base_url)
  path <- sub("/index[.]html$", "/", path)
  xml2::url_absolute(path, base_url)
}

seo_json <- function(value) {
  # Un texte de métadonnées ne doit jamais fermer la balise script.
  json <- as.character(toJSON(value, auto_unbox = TRUE, pretty = TRUE, null = "null"))
  json <- gsub("<", "\\u003c", json, fixed = TRUE)
  json <- gsub(">", "\\u003e", json, fixed = TRUE)
  gsub("&", "\\u0026", json, fixed = TRUE)
}

seo_root_titles <- c(
  "index.html" = "Données bleues | Jeux de données québécois pour enseigner",
  "actualites.html" = "Actualités des jeux de données québécois | Données bleues",
  "catalogue.html" = "Jeux de données québécois pour l’enseignement | Données bleues",
  "activites.html" = "Activités de statistique et de R | Données bleues",
  "applications.html" = "Outils et tutoriels de statistique et de R | Données bleues",
  "lectures.html" = "Lectures et documents pour enseigner avec des données | Données bleues",
  "ressources.html" = "Rechercher des ressources pédagogiques québécoises | Données bleues"
)

seo_tool_notices <- c(
  "outils/maisons-quebec/index.html" = "explorer-maisons-quebec",
  "outils/bootstrap-maisons/index.html" = "bootstrap-maisons-quebec",
  "outils/permutations-accidents/index.html" = "permutations-accidents-quebec",
  "outils/ggplot-builder/index.html" = "ggplot-builder-donnees-bleues"
)

seo_root_descriptions <- c(
  "index.html" = "Jeux de données québécois, activités pédagogiques, documents et tutoriels pour enseigner la statistique, R et la science des données au cégep et à l’université.",
  "actualites.html" = "Billets sur les nouveaux jeux de données de Données bleues, leurs mises à jour et des pistes pour les explorer et les utiliser en classe.",
  "catalogue.html" = "Explorez les jeux de données du Québec par thème, source et concept statistique. Consultez les fiches, les conditions de réutilisation et les ressources de classe.",
  "ressources.html" = "Recherchez les jeux de données, activités, documents, outils et tutoriels de Données bleues par thème, auteur ou source et cours d’utilisation.",
  "activites.html" = "Choisissez une activité de statistique ou de programmation R avec des données québécoises selon les concepts, les prérequis et la durée de la séance.",
  "lectures.html" = "Lectures et documents sur les données québécoises, la statistique et leur enseignement : articles, notes et démonstrations avec sources documentées.",
  "applications.html" = "Outils interactifs et tutoriels pour explorer des données québécoises et apprendre la statistique, la visualisation et la programmation R.",
  "guide.html" = "Découvrez comment utiliser les fiches de données, activités pédagogiques, documents, outils et trousses de classe du site Données bleues.",
  "about.html" = "Découvrez le projet Données bleues, ses contributeurs et son objectif : enseigner la statistique, R et la science des données avec des ressources québécoises.",
  "contribuer.html" = "Proposez un jeu de données, une activité, un document ou un outil à Données bleues. Consultez les exigences de provenance, de licence et de documentation.",
  "charte-editoriale.html" = "Consignes de rédaction des fiches de données et activités de Données bleues : sources, périodes, limites, conditions de réutilisation et contributions.",
  "zero-waste.html" = "Cadre de réutilisation pédagogique des données de Données bleues pour construire des activités de nettoyage, visualisation, statistique et modélisation.",
  "retours-classe.html" = "Documentez l’utilisation d’une ressource Données bleues en classe, les difficultés rencontrées et les adaptations, sans recueillir de données personnelles étudiantes.",
  "sequences.html" = "Parcours et séquences pédagogiques de Données bleues pour organiser des activités de statistique et de science des données avec des jeux québécois.",
  "references.html" = "Sources et références du projet Données bleues pour les données québécoises, la statistique, la programmation R et les ressources pédagogiques.",
  "credits-images.html" = "Crédits et provenance des illustrations de Données bleues : sources, conditions de réutilisation et distinction entre illustrations et observations réelles.",
  "donnees-ulaval.html" = "Documentation des données institutionnelles de l’Université Laval dans Données bleues, avec les limites d’accès, de confidentialité et de réutilisation."
)

seo_dataset <- function(metadata, page_url, output_dir, base_url) {
  result <- list(
    "@context" = "https://schema.org", "@type" = "Dataset",
    "@id" = paste0(page_url, "#dataset"), url = page_url,
    name = metadata$title, description = metadata$summary,
    inLanguage = "fr", identifier = metadata$id,
    includedInDataCatalog = list("@type" = "DataCatalog", name = "Données bleues",
                                url = seo_url("catalogue.html", base_url))
  )
  keywords <- unique(c(metadata$tags, metadata$concepts))
  if (length(keywords)) result$keywords <- as.list(keywords)
  if (nzchar(seo_text(metadata$geography))) {
    result$spatialCoverage <- list("@type" = "Place", name = seo_text(metadata$geography))
  }
  if (length(metadata$variables_principales)) result$variableMeasured <- as.list(metadata$variables_principales)

  # La période libre reste du texte : ne pas déduire une plage ISO de dates ambiguës.
  if (nzchar(seo_text(metadata$observation_period))) {
    result$temporal <- seo_text(metadata$observation_period)
  }
  # Les producteurs d'origine ne deviennent pas les créateurs de l'adaptation.
  # Les métadonnées actuelles ne déclarent pas leur type Person/Organization.
  if (nzchar(seo_text(metadata$source_url))) {
    result$isBasedOn <- list("@type" = "CreativeWork", name = metadata$source_name,
      url = metadata$source_url)
    if (length(metadata$source_authors)) {
      result$isBasedOn$description <- paste0("Source des données : ", seo_text(metadata$source_authors))
    }
  }
  terms_url <- metadata$publication$license_url
  if (nzchar(seo_text(metadata$license))) {
    result$usageInfo <- list("@type" = "CreativeWork", name = metadata$license)
    if (nzchar(seo_text(terms_url))) result$usageInfo$url <- terms_url
    # Seules les licences uniques explicitement documentées sont déclarées ici.
    simple_cc_by <- identical(metadata$license, "CC BY 4.0") ||
      grepl("^Attribution [(]CC-BY 4[.]0[)]( selon les métadonnées CKAN.*)?$", metadata$license)
    if (simple_cc_by && nzchar(seo_text(terms_url))) result$license <- terms_url
  }
  downloads <- list()
  if (nzchar(seo_text(metadata$download_url))) {
    download <- xml2::url_absolute(metadata$download_url, page_url)
    item <- list("@type" = "DataDownload", contentUrl = download)
    if (grepl("[.]csv$", download, ignore.case = TRUE)) item$encodingFormat <- "text/csv"
    downloads <- list(item)
  }
  archive <- paste0("assets/classroom/", metadata$id, ".zip")
  # Une trousse de scripts d'acquisition n'est pas une distribution des données.
  if (identical(metadata$publication$classroom$mode, "frozen") &&
      file.exists(file.path(output_dir, archive))) {
    downloads <- append(downloads, list(list("@type" = "DataDownload",
      contentUrl = seo_url(archive, base_url), encodingFormat = "application/zip")))
  }
  if (length(downloads)) result$distribution <- downloads
  result
}

seo_page_metadata <- function(path, document, items, datasets, base_url) {
  title <- seo_text(xml_text(xml_find_first(document, "//title")))
  if (path %in% names(seo_root_titles)) title <- seo_root_titles[[path]]
  item <- items[[path]]
  tool_path <- sub("/edit/index[.]html$", "/index.html", path)
  editor <- path != tool_path && tool_path %in% names(seo_tool_notices)
  if (tool_path %in% names(seo_tool_notices)) {
    item <- items[[paste0("resources/", seo_tool_notices[[tool_path]], ".html")]]
    if (is.null(item)) stop("Notice d'application absente : ", path, call. = FALSE)
    title <- paste0(if (editor) "Éditeur : " else "", item$title, " | Données bleues")
  }
  description <- if (path %in% names(seo_root_descriptions)) seo_root_descriptions[[path]] else NULL
  if (is.null(description) && !is.null(item)) description <- item$description
  if (!nzchar(seo_text(description))) {
    description <- xml_attr(xml_find_first(document, '//meta[@name="description"]'), "content")
  }
  if (!nzchar(seo_text(description))) {
    paragraphs <- xml_text(xml_find_all(document, '//main//p[not(ancestor::details) and not(ancestor::pre)]'))
    paragraphs <- vapply(paragraphs, seo_text, character(1))
    paragraphs <- paragraphs[nchar(paragraphs) >= 50L]
    if (!length(paragraphs)) stop("Description à renseigner : ", path, call. = FALSE)
    description <- paragraphs[[1]]
  }
  description <- seo_text(description)
  # Les résumés Dataset restent complets; l'extrait HTML se termine à un mot.
  if (nchar(description) > 240L) {
    description <- paste0(sub("[[:space:]]+[^[:space:]]*$", "", substr(description, 1L, 237L)), "…")
  }
  image <- "assets/cards/catalogue.png"
  image_alt <- "Illustration du catalogue de ressources Données bleues"
  image_dataset <- datasets[[path]]
  if (is.null(image_dataset) && startsWith(path, "datasets/")) {
    image_dataset <- datasets[[paste0(dirname(path), "/fiche.html")]]
  }
  if (is.null(image_dataset) && length(item$related_datasets)) {
    image_dataset <- datasets[[paste0("datasets/", item$related_datasets[[1]], "/fiche.html")]]
  }
  if (!is.null(image_dataset)) {
    image <- paste0("assets/illustrations/datasets/", image_dataset$id, ".webp")
    image_alt <- paste0("Illustration du jeu de données : ", image_dataset$title)
  }
  list(title = title, description = description, url = seo_url(path, base_url),
       image = seo_url(image, base_url), image_alt = image_alt, noindex = editor)
}

seo_replace_head <- function(html, metadata, structured_data = NULL) {
  position <- regexpr("(?s)<head\\b[^>]*>.*?</head>", html, perl = TRUE)
  if (position[[1]] < 0L) stop("Élément head absent.", call. = FALSE)
  head <- regmatches(html, position)
  head <- gsub("(?s)\\n<!-- db-seo:start -->.*?<!-- db-seo:end -->\\n", "", head, perl = TRUE)
  head <- gsub("(?s)<title\\b[^>]*>.*?</title>", "", head, perl = TRUE)
  tags <- unique(regmatches(head, gregexpr("<(?:meta|link)\\b[^>]*>", head, perl = TRUE))[[1]])
  for (tag in tags) {
    node <- xml_find_first(read_html(paste0("<html><head>", tag, "</head></html>")), "//meta|//link")
    key <- xml_attr(node, "name")
    property <- xml_attr(node, "property")
    rel <- xml_attr(node, "rel")
    remove <- (!is.na(key) && (key == "description" || startsWith(key, "twitter:"))) ||
      (!is.na(property) && startsWith(property, "og:")) || (!is.na(rel) && rel == "canonical")
    if (remove) head <- gsub(tag, "", head, fixed = TRUE)
  }
  escape <- function(value) as.character(htmlEscape(value, attribute = TRUE))
  meta <- function(key, value, attribute = "name") {
    paste0('<meta ', attribute, '="', key, '" content="', escape(value), '">')
  }
  block <- c("<!-- db-seo:start -->", paste0("<title>", escape(metadata$title), "</title>"),
    paste0('<link rel="canonical" href="', escape(metadata$url), '">'),
    meta("description", metadata$description),
    meta("og:title", metadata$title, "property"), meta("og:description", metadata$description, "property"),
    meta("og:url", metadata$url, "property"), meta("og:type", "website", "property"),
    meta("og:site_name", "Données bleues", "property"), meta("og:locale", "fr_CA", "property"),
    meta("og:image", metadata$image, "property"), meta("og:image:alt", metadata$image_alt, "property"),
    meta("twitter:card", "summary_large_image"), meta("twitter:title", metadata$title),
    meta("twitter:description", metadata$description), meta("twitter:image", metadata$image),
    meta("twitter:image:alt", metadata$image_alt))
  if (!is.null(structured_data)) {
    block <- c(block, '<script type="application/ld+json" id="db-dataset-jsonld">',
               seo_json(structured_data), "</script>")
  }
  if (isTRUE(metadata$noindex)) block <- c(block, meta("robots", "noindex, follow"))
  block <- c(block, "<!-- db-seo:end -->")
  # Replacer la portion head uniquement conserve le HTML visible octet pour octet.
  head <- paste0(substr(head, 1L, nchar(head) - nchar("</head>")), "\n",
                 paste(block, collapse = "\n"), "\n</head>")
  regmatches(html, position) <- head
  html
}

postprocess_site_seo <- function(output_dir = "docs", paths = NULL) {
  source("R/utils_resources.R", local = TRUE)
  source("R/utils_catalogue.R", local = TRUE)
  config <- read_yaml("_quarto.yml")
  base_url <- config$website$site_url
  if (is.null(base_url)) base_url <- config$website[["site-url"]]
  stopifnot(length(base_url) == 1L, grepl("^https://.+/$", base_url))
  resources <- resource_catalogue()
  items <- setNames(resources, vapply(resources, `[[`, character(1), "url"))
  catalogue <- build_catalogue("datasets")
  datasets <- setNames(lapply(catalogue$id, function(id) read_dataset_metadata(file.path("datasets", id))),
                       sub("[.]qmd$", ".html", catalogue$fiche))
  sitemap_path <- file.path(output_dir, "sitemap.xml")
  urls <- if (!is.null(paths) && file.exists(sitemap_path)) {
    xml_text(xml_find_all(read_xml(sitemap_path), '//*[local-name()="loc"]'))
  } else character()
  if (is.null(paths)) paths <- sort(list.files(output_dir, pattern = "[.]html$", recursive = TRUE))
  stopifnot(all(file.exists(file.path(output_dir, paths))))
  urls <- setdiff(urls, vapply(paths, seo_url, character(1), base_url = base_url))
  for (path in paths) {
    file <- file.path(output_dir, path)
    html <- paste(readLines(file, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
    document <- read_html(html)
    directives <- xml_attr(xml_find_all(document, '//meta[@name="robots"]'), "content")
    noindex <- any(grepl("noindex", directives, ignore.case = TRUE))
    metadata <- seo_page_metadata(path, document, items, datasets, base_url)
    dataset <- datasets[[path]]
    structured <- if (!is.null(dataset)) seo_dataset(dataset, metadata$url, output_dir, base_url) else NULL
    html <- seo_replace_head(html, metadata, structured)
    writeChar(html, file, eos = NULL, useBytes = TRUE)
    if (!noindex && !metadata$noindex) urls <- c(urls, metadata$url)
  }
  # Quarto rend les pages séparément; finaliser après les démonstrations autonomes.
  # Pas de lastmod : les dates des fiches ne datent pas chaque reconstruction HTML.
  sitemap <- xml_new_root("urlset", xmlns = "http://www.sitemaps.org/schemas/sitemap/0.9")
  for (url in unique(urls)) xml_add_child(xml_add_child(sitemap, "url"), "loc", url)
  write_xml(sitemap, file.path(output_dir, "sitemap.xml"))
  writeLines(c("User-agent: *", "Allow: /", "", paste0("Sitemap: ", base_url, "sitemap.xml")),
             file.path(output_dir, "robots.txt"))
  message(length(paths), " pages finalisées; ", length(unique(urls)), " URL dans le sitemap; ",
          length(datasets), " fiches Dataset au catalogue.")
  invisible(urls)
}
