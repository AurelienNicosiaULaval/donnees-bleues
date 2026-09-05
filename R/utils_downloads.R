# Provenance des acquisitions. Exécuter les préparations depuis la racine du projet.
# Les empreintes portent sur les octets du fichier indiqué, sans modifier la source.
source_timestamp <- function() format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")

record_source <- function(path, url, kind = "download", details = NULL, started_at = NULL) {
  stopifnot(file.exists(path), length(url) == 1L, nzchar(url))
  record <- list(
    source_url = url, acquisition_kind = kind,
    acquired_at_utc = source_timestamp(), started_at_utc = started_at,
    file = basename(path), bytes = unname(file.info(path)$size),
    sha256 = digest::digest(file = path, algo = "sha256"), details = details
  )
  jsonlite::write_json(record, paste0(path, ".source.json"), auto_unbox = TRUE, pretty = TRUE)
  invisible(path)
}

download_source <- function(url, destfile, mode = "wb", quiet = TRUE, handle = NULL, ...) {
  receipt_path <- paste0(destfile, ".source.json")
  if (identical(Sys.getenv("DB_OFFLINE"), "true")) {
    if (!file.exists(destfile) || !file.exists(receipt_path)) {
      stop("Mode hors ligne : source et manifeste requis pour ", destfile, call. = FALSE)
    }
    receipt <- jsonlite::read_json(receipt_path, simplifyVector = TRUE)
    if (!identical(receipt$source_url, url) ||
        !identical(receipt$sha256, digest::digest(file = destfile, algo = "sha256"))) {
      stop("Le fichier source diffère du manifeste : ", destfile, call. = FALSE)
    }
    return(invisible(0L))
  }
  dir.create(dirname(destfile), recursive = TRUE, showWarnings = FALSE)
  temporary <- tempfile("acquisition-", tmpdir = dirname(destfile))
  on.exit(unlink(temporary), add = TRUE)
  started <- source_timestamp()
  # Un téléchargement incomplet ne remplace jamais le fichier de travail précédent.
  if (is.null(handle)) {
    status <- utils::download.file(url, temporary, mode = mode, quiet = quiet, ...)
    if (!identical(status, 0L)) stop("Échec du téléchargement : ", url, call. = FALSE)
  } else {
    curl::curl_download(url, temporary, quiet = quiet, handle = handle, ...)
  }
  if (!file.exists(temporary) || file.info(temporary)$size == 0) {
    stop("Le téléchargement est vide : ", url, call. = FALSE)
  }
  if (!file.rename(temporary, destfile)) stop("Impossible de finaliser ", destfile, call. = FALSE)
  record_source(destfile, url, started_at = started)
  invisible(0L)
}

record_preparation <- function(id) {
  directory <- file.path("data/processed", id)
  files <- list.files(directory, pattern = "[.]csv$", full.names = TRUE)
  if (!length(files)) stop("Aucun CSV produit pour ", id, call. = FALSE)
  receipts <- list.files(file.path("data/raw", id), pattern = "[.]source[.]json$", recursive = TRUE, full.names = TRUE)
  sources <- lapply(receipts, jsonlite::read_json, simplifyVector = TRUE)
  tables <- lapply(files, function(file) {
    data <- readr::read_csv(file, col_types = readr::cols(.default = readr::col_character()), show_col_types = FALSE)
    list(file = basename(file), rows = nrow(data), columns = names(data), bytes = unname(file.info(file)$size),
         sha256 = digest::digest(file = file, algo = "sha256"))
  })
  script <- file.path("datasets", id, "preparation.R")
  manifest <- list(dataset_id = id, prepared_at_utc = source_timestamp(),
    r_version = as.character(getRversion()), script_sha256 = digest::digest(file = script, algo = "sha256"),
    acquisition_mode = if (identical(Sys.getenv("DB_OFFLINE"), "true")) "cached_sources" else "current_run",
    sources = sources, tables = tables)
  jsonlite::write_json(manifest, file.path(directory, "manifest.json"), auto_unbox = TRUE, pretty = TRUE)
  invisible(manifest)
}
