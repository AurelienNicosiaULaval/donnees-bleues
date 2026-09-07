# Verify that readers can download and reproduce the exact published lessons.
local({
  directory <- "docs/demonstrations"
  stems <- c("01-ilots-chaleur", "02-acp-quebec", "03-crues-saint-charles")
  archive <- file.path(directory, "donnees-bleues-trois-demonstrations.zip")
  stage <- tempfile("demonstrations-check-")
  dir.create(stage)
  on.exit(unlink(stage, recursive = TRUE))
  entries <- utils::unzip(archive, exdir = stage)
  required <- c(paste0(stems, ".qmd"), paste0(stems, ".html"),
    "README.md", "PROVENANCE.md", "_quarto.yml", "_navigation.html", "styles.css", "INSTALLER.R",
    "Demonstrations-Donnees-bleues.Rproj", "LICENSE-CODE", "sources/manifest-sha256.csv")
  stopifnot(all(file.exists(file.path(stage, required))))
  manifest <- readr::read_csv(file.path(stage, "sources/manifest-sha256.csv"), show_col_types = FALSE)
  for (i in seq_len(nrow(manifest))) {
    for (root in c(stage, directory)) {
      stopifnot(digest::digest(file = file.path(root, manifest$fichier[i]), algo = "sha256") == manifest$sha256[i])
    }
  }
  for (stem in stems) {
    qmd <- paste0(stem, ".qmd")
    stopifnot(digest::digest(file = file.path(stage, qmd), algo = "sha256") ==
      digest::digest(file = file.path(directory, qmd), algo = "sha256"))
    for (root in c(stage, directory)) {
      doc <- xml2::read_html(file.path(root, paste0(stem, ".html")))
      stopifnot(length(xml2::xml_find_all(doc, "//h1")) == 1L,
        length(xml2::xml_find_all(doc, "//main")) == 1L,
        length(xml2::xml_find_all(doc, "//img")) >= 4L)
      dependencies <- xml2::xml_attr(xml2::xml_find_all(doc, "//img[@src]|//script[@src]"), "src")
      styles <- xml2::xml_attr(xml2::xml_find_all(doc, "//link[@rel='stylesheet']"), "href")
      stopifnot(all(startsWith(c(dependencies, styles), "data:")))
    }
  }
  message("Trois démonstrations autonomes : HTML, Quarto, données et archive vérifiés.")
})
