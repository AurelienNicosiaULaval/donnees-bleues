source("R/utils_seo.R")
base_url <- "https://donneesbleues.ca/"
stopifnot(seo_url("index.html", base_url) == base_url,
          seo_url("outils/maisons-quebec/index.html", base_url) == paste0(base_url, "outils/maisons-quebec/"),
          seo_url("datasets/bixi/fiche.html", base_url) == paste0(base_url, "datasets/bixi/fiche.html"))

# L'échappement protège le JSON et les attributs, sans toucher au contenu visible.
metadata <- list(title = 'Titre " & < >', description = 'Description " & < >',
                 url = base_url, image = paste0(base_url, "assets/cards/catalogue.png"), image_alt = "Illustration")
dataset <- list("@context" = "https://schema.org", "@type" = "Dataset",
                name = "Titre", description = 'Résumé </script><script>alert("x")</script> & test')
original <- '<!DOCTYPE html><html><head><title>Ancien</title><meta content="Ancienne" name="description"><meta property="og:title" content="Ancien"><meta name="google-site-verification" content="preuve"></head><body><main><h1>Titre visible</h1><p>Texte intact.</p></main></body></html>'
final <- seo_replace_head(original, metadata, dataset)
doc <- read_html(final)
stopifnot(identical(sub("(?s)^.*?</head>", "", original, perl = TRUE),
                    sub("(?s)^.*?</head>", "", final, perl = TRUE)),
          identical(seo_replace_head(final, metadata, dataset), final),
          length(xml_find_all(doc, "//head/title")) == 1L,
          xml_text(xml_find_first(doc, "//title")) == metadata$title,
          xml_attr(xml_find_first(doc, '//meta[@name="description"]'), "content") == metadata$description,
          xml_attr(xml_find_first(doc, '//meta[@name="google-site-verification"]'), "content") == "preuve",
          length(xml_find_all(doc, '//script')) == 1L,
          fromJSON(xml_text(xml_find_first(doc, '//script')))$description == dataset$description)
metadata$noindex <- TRUE
editor <- seo_replace_head(original, metadata)
stopifnot(length(xml_find_all(read_html(editor), '//meta[@name="robots"]')) == 1L,
          xml_attr(xml_find_first(read_html(editor), '//meta[@name="robots"]'), "content") == "noindex, follow",
          identical(seo_replace_head(editor, metadata), editor))

# Aucune licence ouverte ou distribution ne doit être attribuée aux données restreintes.
for (id in c("cohortes-diplomation", "ulaval-programmes-cours", "hydro-quebec-temperature", "arbres-quebec")) {
  m <- read_yaml(file.path("datasets", id, "metadata.yml"))
  result <- seo_dataset(m, paste0(base_url, "datasets/", id, "/fiche.html"), "docs", base_url)
  stopifnot(is.null(result$license), identical(result$usageInfo$name, m$license),
            is.null(result$creator), is.null(result$datePublished), is.null(result$temporalCoverage))
  if (id %in% c("cohortes-diplomation", "ulaval-programmes-cours")) stopifnot(is.null(result$distribution))
  if (id == "hydro-quebec-temperature") stopifnot(length(result$distribution) == 1L,
    result$distribution[[1]]$contentUrl == m$download_url)
}
m <- read_yaml("datasets/maisons-quebec/metadata.yml")
result <- seo_dataset(m, paste0(base_url, "datasets/maisons-quebec/fiche.html"), "docs", base_url)
stopifnot(result$license == m$publication$license_url,
          result$distribution[[1]]$contentUrl == paste0(base_url, "assets/data/maisons-quebec.csv"))
message("SEO : échappement, contenu visible, idempotence, URL et conditions de réutilisation vérifiés.")
