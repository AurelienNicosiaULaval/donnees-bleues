source('R/utils_donnees_quebec.R')
source('R/utils_ckan.R')
source('R/utils_downloads.R')

run_dq_tests <- function() {
  registry <- dq_read_registry()
  dq_validate_registry(registry)
  stopifnot(length(dq_sources('arbres-quebec', registry)) == 1L,
    length(dq_sources('construction-quartiers-quebec', registry)) == 3L)
  html <- dq_sources_html('arbres-quebec', registry = registry)
  stopifnot(grepl('Citer les données', html, fixed = TRUE),
    grepl(dq_sources('arbres-quebec', registry)[[1]]$citation, xml2::xml_text(xml2::read_html(html)), fixed = TRUE),
    identical(dq_sources_html('jeu-sans-source', registry = registry), ''))
  missing <- registry
  missing$sources <- Filter(function(x) !'arbres-quebec' %in% unlist(x$dataset_ids), missing$sources)
  stopifnot(inherits(tryCatch(dq_validate_registry(missing), error = identity), 'error'))

  stage <- tempfile('test-dq-'); dir.create(stage)
  on.exit(unlink(stage, recursive = TRUE), add = TRUE)
  old <- Sys.getenv('DB_OFFLINE', unset = NA_character_)
  Sys.unsetenv('DB_OFFLINE')
  on.exit(if (is.na(old)) Sys.unsetenv('DB_OFFLINE') else Sys.setenv(DB_OFFLINE = old), add = TRUE)
  make_fetch <- function(problem = '') {
    function(url, path) {
      offset <- as.integer(sub('.*offset=([0-9]+).*', '\\1', url))
      rows <- lapply(seq.int(offset + 1L, min(offset + 2L, 5L)), function(id)
        list(`_id` = id, code = sprintf('%03d', id), valeur = if (id == 2L) NULL else as.character(id)))
      if (problem == 'empty' && offset > 0L) rows <- list()
      if (problem == 'duplicate' && offset > 0L) rows[[1]]$`_id` <- 1L
      total <- if (problem == 'changed' && offset > 0L) 6L else 5L
      fields <- list(list(id = '_id'), list(id = 'code'), list(id = 'valeur'))
      if (problem == 'schema' && offset > 0L) fields[[3]]$id <- 'autre'
      result <- list(success = TRUE, result = list(resource_id = 'test', total = total,
        fields = fields, records = rows))
      jsonlite::write_json(result, path, auto_unbox = TRUE, null = 'null')
      record_source(path, url)
      result
    }
  }
  path <- file.path(stage, 'complete.csv')
  ckan_datastore_download('test', path, page_size = 2, fetch = make_fetch())
  data <- readr::read_csv(path, col_types = readr::cols(.default = readr::col_character()), show_col_types = FALSE)
  stopifnot(nrow(data) == 5L, identical(data$code, sprintf('%03d', 1:5)), is.na(data$valeur[[2]]))
  receipt <- jsonlite::read_json(paste0(path, '.source.json'))
  stopifnot(length(receipt$details$pages) == 3L)
  Sys.setenv(DB_OFFLINE = 'true')
  ckan_datastore_download('test', path, page_size = 2)
  page <- file.path(dirname(path), receipt$details$pages[[1]]$file)
  writeLines('altéré', page)
  stopifnot(inherits(tryCatch(ckan_datastore_download('test', path), error = identity), 'error'))
  Sys.unsetenv('DB_OFFLINE')
  for (problem in c('empty', 'duplicate', 'changed', 'schema', 'limit')) {
    destination <- file.path(stage, paste0(problem, '.csv'))
    result <- tryCatch(ckan_datastore_download('test', destination, page_size = 2,
      max_records = if (problem == 'limit') 3L else 100L, fetch = make_fetch(problem)), error = identity)
    stopifnot(inherits(result, 'error'), !file.exists(destination))
  }
  message('Données Québec : couverture des citations, pagination, intégrité et échecs vérifiés.')
}
run_dq_tests()
