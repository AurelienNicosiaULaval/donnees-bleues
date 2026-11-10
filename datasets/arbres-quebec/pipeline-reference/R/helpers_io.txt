# Fonctions d'entrée-sortie reproductibles ---------------------------------

assert_packages <- function(packages) {
  missing <- packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing) > 0L) {
    stop(
      "Paquets R manquants : ", paste(missing, collapse = ", "),
      ". Installez-les avant de poursuivre.",
      call. = FALSE
    )
  }
  invisible(TRUE)
}

ensure_project_dirs <- function(root = ".") {
  dirs <- file.path(
    root,
    c("data_raw", "data_intermediate", "data_clean", "R", "scripts",
      "docs", "references", "logs")
  )
  vapply(dirs, dir.create, logical(1), recursive = TRUE, showWarnings = FALSE)
  invisible(dirs)
}

sha256_file <- function(path) {
  if (!file.exists(path)) return(NA_character_)
  digest::digest(file = path, algo = "sha256", serialize = FALSE)
}

write_atomic_csv <- function(x, path, overwrite = FALSE, na = "") {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  if (file.exists(path) && !isTRUE(overwrite)) {
    stop("Le fichier existe déjà et OVERWRITE_CLEAN n'est pas vrai : ", path,
         call. = FALSE)
  }
  tmp <- tempfile(pattern = paste0(basename(path), "."), tmpdir = dirname(path))
  on.exit(unlink(tmp), add = TRUE)
  readr::write_csv(x, tmp, na = na)
  if (file.exists(path)) unlink(path)
  if (!file.rename(tmp, path)) {
    stop("Échec du déplacement atomique vers : ", path, call. = FALSE)
  }
  invisible(path)
}

write_atomic_text <- function(lines, path, overwrite = FALSE) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  if (file.exists(path) && !isTRUE(overwrite)) {
    stop("Le fichier existe déjà : ", path, call. = FALSE)
  }
  tmp <- tempfile(pattern = paste0(basename(path), "."), tmpdir = dirname(path))
  on.exit(unlink(tmp), add = TRUE)
  writeLines(lines, tmp, useBytes = TRUE)
  if (file.exists(path)) unlink(path)
  if (!file.rename(tmp, path)) {
    stop("Échec du déplacement atomique vers : ", path, call. = FALSE)
  }
  invisible(path)
}

as_bool_env <- function(name, default = FALSE) {
  value <- Sys.getenv(name, unset = if (default) "true" else "false")
  tolower(trimws(value)) %in% c("1", "true", "t", "yes", "y", "oui")
}

as_int_env <- function(name, default) {
  value <- suppressWarnings(as.integer(Sys.getenv(name, unset = as.character(default))))
  if (is.na(value)) default else value
}

find_one_file <- function(directory, pattern, required = TRUE) {
  files <- list.files(directory, pattern = pattern, recursive = TRUE,
                      full.names = TRUE, ignore.case = TRUE)
  if (length(files) == 0L) {
    if (required) stop("Aucun fichier correspondant à ", pattern,
                       " dans ", directory, call. = FALSE)
    return(NA_character_)
  }
  if (length(files) > 1L) {
    stop("Plusieurs fichiers correspondent à ", pattern, " : ",
         paste(files, collapse = "; "), call. = FALSE)
  }
  normalizePath(files, winslash = "/", mustWork = TRUE)
}

extract_zip_once <- function(zip_path, destination, overwrite = FALSE) {
  marker <- file.path(destination, ".extraction_complete")
  if (file.exists(marker) && !overwrite) return(invisible(destination))
  if (dir.exists(destination) && length(list.files(destination, all.files = TRUE,
                                                    no.. = TRUE)) > 0L && !overwrite) {
    stop("Le dossier d'extraction n'est pas vide : ", destination,
         ". Supprimez-le ou activez explicitement l'écrasement.", call. = FALSE)
  }
  dir.create(destination, recursive = TRUE, showWarnings = FALSE)
  utils::unzip(zip_path, exdir = destination)
  writeLines(
    c(
      paste("source_zip:", normalizePath(zip_path, winslash = "/")),
      paste("sha256:", sha256_file(zip_path)),
      paste("extracted_utc:", format(Sys.time(), tz = "UTC", usetz = TRUE))
    ),
    marker
  )
  invisible(destination)
}
