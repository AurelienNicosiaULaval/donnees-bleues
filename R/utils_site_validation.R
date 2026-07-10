site_documented_paths <- function(path) {
  if (!file.exists(path)) stop("Document introuvable : ", path, call. = FALSE)

  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  matches <- regmatches(lines, gregexpr("`(?:templates|scripts|R)/[^`]+`", lines, perl = TRUE))
  paths <- gsub("^`|`$", "", unlist(matches, use.names = FALSE))
  unique(paths[nzchar(paths)])
}

validate_documented_paths <- function(documents = c("contribuer.qmd", "README.md"), root = ".") {
  errors <- character()
  for (document in documents[file.exists(file.path(root, documents))]) {
    paths <- site_documented_paths(file.path(root, document))
    missing <- paths[!file.exists(file.path(root, paths))]
    if (length(missing) > 0L) {
      errors <- c(errors, paste0(document, " mentionne des chemins inexistants : ", paste(missing, collapse = ", ")))
    }
  }
  if (length(errors) > 0L) stop(paste(errors, collapse = "\n"), call. = FALSE)
  invisible(TRUE)
}

postprocess_site_headings <- function(output_dir = "docs") {
  if (!requireNamespace("xml2", quietly = TRUE)) stop("Le package xml2 est requis pour finaliser le HTML.", call. = FALSE)

  html_files <- list.files(output_dir, pattern = "[.]html$", recursive = TRUE, full.names = TRUE)
  for (html_file in html_files) {
    document <- xml2::read_html(html_file)
    title_block <- xml2::xml_find_first(document, "//header[@id='title-block-header']")
    headings <- xml2::xml_find_all(document, "//h1")
    if (!inherits(title_block, "xml_missing") && length(headings) > 1L) {
      xml2::xml_remove(title_block)
      xml2::write_html(document, html_file, options = "format")
    }
  }
  validate_rendered_headings(output_dir)
  invisible(html_files)
}

validate_rendered_headings <- function(output_dir = "docs") {
  if (!requireNamespace("xml2", quietly = TRUE)) stop("Le package xml2 est requis pour valider le HTML.", call. = FALSE)

  html_files <- list.files(output_dir, pattern = "[.]html$", recursive = TRUE, full.names = TRUE)
  if (length(html_files) == 0L) stop("Aucune page HTML n'a été trouvée dans ", output_dir, ".", call. = FALSE)

  invalid <- vapply(html_files, function(html_file) {
    length(xml2::xml_find_all(xml2::read_html(html_file), "//h1")) != 1L
  }, logical(1))
  if (any(invalid)) {
    stop("Chaque page HTML doit avoir un seul titre h1. Pages invalides : ", paste(html_files[invalid], collapse = ", "), call. = FALSE)
  }
  invisible(TRUE)
}
