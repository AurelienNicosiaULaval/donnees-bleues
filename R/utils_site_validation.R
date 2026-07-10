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
    html <- paste(readLines(html_file, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
    title_start <- regexpr("<header[^>]+id=[\"']title-block-header[\"'][^>]*>", html, perl = TRUE)
    title_end <- if (title_start[1] > 0L) {
      regexpr("</header>", substr(html, title_start[1], nchar(html)), fixed = TRUE)
    } else {
      -1L
    }

    if (title_start[1] > 0L && title_end[1] > 0L) {
      before <- if (title_start[1] == 1L) "" else substr(html, 1L, title_start[1] - 1L)
      after_start <- title_start[1] + title_end[1] + nchar("</header>") - 1L
      after <- if (after_start >= nchar(html)) "" else substr(html, after_start + 1L, nchar(html))
      html <- paste0(before, after)
      writeChar(html, html_file, eos = NULL, useBytes = TRUE)
    }

    document <- xml2::read_html(html_file)
    headings <- xml2::xml_find_all(document, "//h1")
    title_block <- xml2::xml_find_first(
      document,
      "//*[contains(concat(' ', normalize-space(@class), ' '), ' quarto-title ')]"
    )
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
