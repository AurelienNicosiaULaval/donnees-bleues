ckan_action <- function(action, query = list(), base_url = "https://www.donneesquebec.ca/recherche") {
  if (!requireNamespace("httr2", quietly = TRUE)) {
    stop("Le package httr2 est requis.", call. = FALSE)
  }

  endpoint <- paste0(gsub("/+$", "", base_url), "/api/3/action/", action)
  request <- httr2::request(endpoint)

  if (length(query) > 0L) {
    request <- do.call(httr2::req_url_query, c(list(request), query))
  }

  request <- httr2::req_timeout(request, 60)
  request <- httr2::req_retry(request, max_tries = 3)
  response <- httr2::req_perform(request)
  payload <- httr2::resp_body_json(response, simplifyVector = TRUE)

  if (!isTRUE(payload$success)) {
    error_message <- payload$error$message
    if (is.null(error_message)) {
      error_message <- paste("Erreur CKAN pour l'action", action)
    }
    stop(error_message, call. = FALSE)
  }

  payload$result
}

# Téléchargement paginé complet. Les réponses et les requêtes restent avec le CSV.
# Une limite de sécurité atteinte provoque une erreur, jamais un extrait silencieux.
ckan_datastore_download <- function(resource_id, destfile, page_size = 5000L,
                                    max_records = 1000000L,
                                    base_url = 'https://www.donneesquebec.ca/recherche',
                                    fetch = NULL, fields = NULL) {
  stopifnot(length(resource_id) == 1L, nzchar(resource_id), page_size >= 1L,
            max_records >= 1L)
  if (!is.null(fields) && (!length(fields) || anyNA(fields) || any(!nzchar(fields)) ||
                           any(grepl(',', fields, fixed = TRUE)) || anyDuplicated(fields)))
    stop('Sélection de champs invalide.', call. = FALSE)
  requested_fields <- fields
  source(if (file.exists('R/utils_downloads.R')) 'R/utils_downloads.R' else '../../R/utils_downloads.R', local = TRUE)
  endpoint <- paste0(sub('/+$', '', base_url), '/api/3/action/datastore_search')
  if (identical(Sys.getenv('DB_OFFLINE'), 'true')) {
    receipt <- jsonlite::read_json(paste0(destfile, '.source.json'))
    if (!identical(receipt$source_url, endpoint) ||
        !identical(receipt$details$resource_id, resource_id) ||
        !identical(receipt$sha256, digest::digest(file = destfile, algo = 'sha256')))
      stop('Cache API absent ou altéré.', call. = FALSE)
    for (page in receipt$details$pages) {
      path <- file.path(dirname(destfile), page$file)
      download_source(page$url, path)
    }
    return(invisible(destfile))
  }
  dir.create(dirname(destfile), recursive = TRUE, showWarnings = FALSE)
  stage <- tempfile('api-', tmpdir = dirname(destfile))
  dir.create(stage)
  on.exit(unlink(stage, recursive = TRUE), add = TRUE)
  if (is.null(fetch)) fetch <- function(url, path) {
    download_source(url, path)
    jsonlite::read_json(path, simplifyVector = FALSE)
  }
  offset <- 0L; expected <- NULL; schema <- NULL; records <- list(); pages <- list()
  repeat {
    query <- list(resource_id = resource_id, limit = page_size, offset = offset,
                  sort = '_id asc', include_total = 'true')
    if (!is.null(requested_fields)) query$fields <- paste(unique(c('_id', requested_fields)), collapse = ',')
    request <- do.call(httr2::req_url_query, c(list(httr2::request(endpoint)), query))
    url <- request$url
    name <- paste0(basename(destfile), '.pages/page-', sprintf('%08d', offset), '.json')
    path <- file.path(stage, name)
    dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
    payload <- fetch(url, path)
    if (!isTRUE(payload$success)) stop('Échec de la requête DataStore.', call. = FALSE)
    result <- payload$result
    if (!identical(result$resource_id, resource_id)) stop('Ressource API inattendue.', call. = FALSE)
    total <- result$total
    if (is.null(total) || length(total) != 1L || !is.numeric(total) || total < 0 ||
        !is.finite(total) || total != floor(total) || isTRUE(result$total_was_estimated))
      stop('Effectif exact indisponible.', call. = FALSE)
    if (is.null(expected)) expected <- total
    if (total != expected) stop('Le nombre de lignes a changé pendant la collecte.', call. = FALSE)
    if (total > max_records) stop('Limite de sécurité dépassée; augmenter max_records explicitement.', call. = FALSE)
    returned_fields <- vapply(result$fields, function(x) x$id, character(1))
    if (is.null(schema)) schema <- returned_fields
    if (!identical(schema, returned_fields) || !'_id' %in% schema ||
        (!is.null(requested_fields) && !setequal(returned_fields, unique(c('_id', requested_fields)))))
      stop('Schéma API variable ou identifiant de pagination absent.', call. = FALSE)
    batch <- result$records
    if (!is.null(requested_fields) && any(vapply(batch, function(row) {
      length(setdiff(names(row), unique(c('_id', requested_fields)))) > 0L
    }, logical(1)))) stop('La réponse contient des champs non demandés.', call. = FALSE)
    if (length(batch) > page_size || offset + length(batch) > total)
      stop('Pagination API incohérente.', call. = FALSE)
    if (!length(batch) && offset < total) stop('Page API vide avant la fin.', call. = FALSE)
    records <- c(records, batch)
    pages[[length(pages) + 1L]] <- list(file = name, url = url,
      sha256 = digest::digest(file = path, algo = 'sha256'))
    offset <- offset + length(batch)
    if (offset == total) break
  }
  ids <- vapply(records, function(x) as.numeric(x$`_id`), numeric(1))
  if (anyNA(ids) || anyDuplicated(ids) || is.unsorted(ids, strictly = TRUE))
    stop('Identifiants répétés ou désordonnés pendant la pagination.', call. = FALSE)
  columns <- setdiff(schema, '_id')
  # Conserver les identifiants et nombres publiés comme texte; pas d'inférence de type.
  table <- as.data.frame(setNames(lapply(columns, function(column) vapply(records, function(row) {
    value <- row[[column]]
    if (is.null(value)) return(NA_character_)
    if (length(value) != 1L || is.list(value)) stop('Champ non scalaire : ', column, call. = FALSE)
    as.character(value)
  }, character(1))), columns), check.names = FALSE, stringsAsFactors = FALSE)
  candidate <- file.path(stage, 'result.csv')
  readr::write_csv(table, candidate, na = 'NA')
  # Aucun fichier existant n'est remplacé : choisir un nouveau dossier d'acquisition.
  if (file.exists(destfile) || dir.exists(paste0(destfile, '.pages')))
    stop('Destination déjà présente; choisir un nouvel instantané.', call. = FALSE)
  if (!file.rename(file.path(stage, paste0(basename(destfile), '.pages')), paste0(destfile, '.pages')))
    stop('Impossible de conserver les réponses API.', call. = FALSE)
  if (!file.rename(candidate, destfile)) stop('Impossible de finaliser le CSV API.', call. = FALSE)
  record_source(destfile, endpoint, kind = 'ckan_datastore', details = list(
    resource_id = resource_id, rows = total, columns = columns, pages = pages,
    pagination_order = '_id asc', snapshot_limit = 'Une collecte paginée ne constitue pas une transaction atomique du serveur.'))
  invisible(destfile)
}

ckan_resource_download <- function(package_id, resource_id, directory,
                                   max_records = 1000000L, page_size = 5000L, fields = NULL) {
  source('R/utils_downloads.R', local = TRUE)
  dir.create(directory, recursive = TRUE, showWarnings = FALSE)
  api <- paste0('https://www.donneesquebec.ca/recherche/api/3/action/package_show?id=',
                utils::URLencode(package_id, reserved = TRUE))
  metadata_path <- file.path(directory, 'package.json')
  download_source(api, metadata_path)
  payload <- jsonlite::read_json(metadata_path)
  if (!isTRUE(payload$success)) stop('Métadonnées CKAN invalides.', call. = FALSE)
  matches <- Filter(function(x) identical(x$id, resource_id), payload$result$resources)
  if (length(matches) != 1L) stop('Ressource absente ou ambiguë dans le jeu déclaré.', call. = FALSE)
  resource <- matches[[1]]
  if (isTRUE(resource$datastore_active)) {
    path <- file.path(directory, 'donnees-api.csv')
    ckan_datastore_download(resource_id, path, max_records = max_records, page_size = page_size, fields = fields)
  } else {
    # Le lien officiel est résolu depuis l'API; pas de sélection du premier fichier.
    format <- tolower(resource$format)
    extension <- if (format == 'gbfs') 'json' else
      if (format %in% c('csv', 'json', 'xml', 'zip', 'xlsx', 'xls', 'geojson', 'pdf', 'gpkg')) format else 'bin'
    path <- file.path(directory, paste0('ressource.', extension))
    if (file.exists(path) && !identical(Sys.getenv('DB_OFFLINE'), 'true'))
      stop('Destination déjà présente; choisir un nouvel instantané.', call. = FALSE)
    download_source(resource$url, path)
    if (format %in% c('gbfs', 'json', 'geojson')) {
      jsonlite::read_json(path)
      if (!identical(Sys.getenv('DB_OFFLINE'), 'true'))
        record_source(path, resource$url, kind = 'native_json_api',
          details = list(package_id = package_id, resource_id = resource_id))
    }
  }
  invisible(path)
}

ckan_package_search <- function(q, rows = 10, start = 0, base_url = "https://www.donneesquebec.ca/recherche") {
  ckan_action(
    "package_search",
    query = list(q = q, rows = rows, start = start),
    base_url = base_url
  )
}

ckan_package_show <- function(id, base_url = "https://www.donneesquebec.ca/recherche") {
  ckan_action(
    "package_show",
    query = list(id = id),
    base_url = base_url
  )
}

ckan_resource_show <- function(id, base_url = "https://www.donneesquebec.ca/recherche") {
  ckan_action(
    "resource_show",
    query = list(id = id),
    base_url = base_url
  )
}
