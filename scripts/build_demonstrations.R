# Recompute the three standalone lessons and package the exact inputs with their HTML.
local({
  root <- normalizePath(".")
  input_dir <- file.path(root, "publication/demonstrations")
  output_dir <- file.path(root, "docs/demonstrations")
  stems <- c("01-ilots-chaleur", "02-acp-quebec", "03-crues-saint-charles")
  manifest <- readr::read_csv(file.path(input_dir, "sources/manifest-sha256.csv"), show_col_types = FALSE)
  for (i in seq_len(nrow(manifest))) {
    path <- file.path(input_dir, manifest$fichier[i])
    stopifnot(file.exists(path), file.info(path)$size == manifest$octets[i],
      digest::digest(file = path, algo = "sha256") == manifest$sha256[i])
  }

  previous_dir <- setwd(input_dir)
  on.exit(setwd(previous_dir))
  status <- system2("quarto", c("render", "--execute", "--no-cache"))
  if (status != 0L) stop("Le rendu des démonstrations a échoué.", call. = FALSE)
  writeLines(trimws(c(paste("Validation UTC :", format(Sys.time(), tz = "UTC", usetz = TRUE)),
    capture.output(utils::sessionInfo()),
    paste("Quarto", system2("quarto", "--version", stdout = TRUE))), which = "right"), "ENVIRONNEMENT.txt")

  package_files <- c(paste0(stems, ".qmd"), paste0(stems, ".html"),
    "_quarto.yml", "_navigation.html", "styles.css", "INSTALLER.R", "README.md",
    "PROVENANCE.md", "LICENSE-CODE", "ENVIRONNEMENT.txt", "Demonstrations-Donnees-bleues.Rproj",
    list.files("data", full.names = TRUE), list.files("sources", full.names = TRUE))
  stopifnot(all(file.exists(package_files)), all(!dir.exists(package_files)))
  zip_path <- tempfile(fileext = ".zip")
  on.exit(unlink(zip_path), add = TRUE)
  status <- utils::zip(zip_path, files = package_files, flags = "-q9X")
  if (status != 0L) stop("Impossible de construire la trousse des démonstrations.", call. = FALSE)
  archive_name <- "donnees-bleues-trois-demonstrations.zip"
  stopifnot(file.copy(zip_path, archive_name, overwrite = TRUE))

  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  # The navigation fragment belongs in the download, not among standalone web pages.
  for (path in c(setdiff(package_files, "_navigation.html"), archive_name)) {
    target <- file.path(output_dir, path)
    dir.create(dirname(target), recursive = TRUE, showWarnings = FALSE)
    stopifnot(file.copy(path, target, overwrite = TRUE))
  }
  # Include the full lessons in the website index as well as their resource notices.
  index_path <- file.path(root, "docs/search.json")
  index <- jsonlite::read_json(index_path)
  hrefs <- paste0("demonstrations/", stems, ".html")
  index <- Filter(function(item) !sub("#.*$", "", item$href) %in% hrefs, index)
  for (i in seq_along(stems)) {
    doc <- xml2::read_html(file.path(output_dir, paste0(stems[i], ".html")))
    stopifnot(length(xml2::xml_find_all(doc, "//h1")) == 1L,
      length(xml2::xml_find_all(doc, "//main")) == 1L)
    images <- xml2::xml_find_all(doc, "//img")
    stopifnot(length(images) >= 4L, all(startsWith(xml2::xml_attr(images, "src"), "data:")))
    index <- append(index, list(list(objectID = hrefs[i], href = hrefs[i],
      title = xml2::xml_text(xml2::xml_find_first(doc, "//h1")),
      section = "", text = xml2::xml_text(xml2::xml_find_first(doc, "//main")))))
  }
  jsonlite::write_json(index, index_path, auto_unbox = TRUE, pretty = TRUE)
  message("Trois démonstrations recalculées, indexées et empaquetées avec leurs données.")
})
