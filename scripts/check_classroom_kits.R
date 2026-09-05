source('R/utils_classroom.R')
root <- normalizePath('.')
output <- file.path(root, 'data/validation/classroom')
dir.create(output, recursive = TRUE, showWarnings = FALSE)
with_source_data <- '--with-source-data' %in% commandArgs(trailingOnly = TRUE)
paths <- sort(list.files('datasets', pattern = '^metadata[.]yml$', recursive = TRUE, full.names = TRUE))
failures <- character(); results <- list()
for (path in paths) {
  metadata <- yaml::read_yaml(path); id <- metadata$id
  policy <- classroom_policy(metadata)
  archive <- file.path('assets/classroom', paste0(id, '.zip'))
  receipt <- jsonlite::read_json(paste0(archive, '.json'))
  if (classroom_sha(archive) != receipt$archive_sha256) stop('Empreinte ZIP incorrecte : ', id)
  entries <- utils::unzip(archive, list = TRUE)$Name
  if (any(grepl('(^/|(^|/)\\.\\.(/|$))', entries))) stop('Chemin ZIP dangereux.')
  stage <- tempfile(paste0('classroom-', id, '-'))
  dir.create(stage)
  utils::unzip(archive, exdir = stage)
  expected_files <- readLines(file.path(stage, 'SHA256SUMS'))
  for (line in expected_files) {
    hash <- substr(line, 1, 64); file <- substring(line, 67)
    if (classroom_sha(file.path(stage, file)) != hash) stop('Empreinte de fichier incorrecte : ', file)
  }
  declared <- vapply(policy$files, function(file) file$path, character(1))
  csv_entries <- entries[grepl('[.]csv$', entries)]
  if (!setequal(csv_entries, declared)) stop('CSV du ZIP différents de la politique : ', id)
  for (file in policy$files) {
    data <- readr::read_csv(file.path(stage, file$path), col_types = readr::cols(.default = readr::col_character()), show_col_types = FALSE)
    if (!identical(names(data), unlist(file$columns, use.names = FALSE))) stop('Colonnes ZIP incorrectes : ', id)
  }
  for (script in classroom_script_paths(id)) {
    if (classroom_sha(script) != classroom_sha(file.path(stage, script))) stop('Script ZIP périmé : ', script)
  }
  if (policy$mode == 'source_required' && with_source_data) {
    # Private test input only, never added to the public ZIP or its manifest.
    dir.create(file.path(stage, 'data/processed'), recursive = TRUE)
    if (!file.copy(file.path(root, 'data/processed', id), file.path(stage, 'data/processed'), recursive = TRUE)) {
      stop('Données acquises localement absentes : ', id)
    }
  }
  for (script in classroom_script_paths(id)) {
    key <- paste(id, tools::file_path_sans_ext(basename(script)), sep = '-')
    if (policy$mode == 'source_required' && !with_source_data) {
      results[[key]] <- list(status = 'source_required', note = 'Acquisition préalable; CSV absents du ZIP par choix de diffusion.')
      next
    }
    directory <- file.path(output, key)
    dir.create(directory, recursive = TRUE, showWarnings = FALSE)
    args <- vapply(c(file.path(root, 'scripts/run_activity.R'), file.path(stage, script), directory, stage), shQuote, character(1))
    code <- system2(file.path(R.home('bin'), 'Rscript'), args,
      stdout = file.path(directory, 'run.log'), stderr = file.path(directory, 'run.log'),
      env = paste0('R_LIBS=', shQuote(paste(.libPaths(), collapse = .Platform$path.sep))))
    result_file <- file.path(directory, 'result.json')
    results[[key]] <- if (file.exists(result_file)) jsonlite::read_json(result_file) else list(status = 'error', exit_code = code)
    if (code != 0L) failures <- c(failures, key)
    cat(key, ':', results[[key]]$status, '\n')
  }
  unlink(stage, recursive = TRUE)
}
jsonlite::write_json(results, file.path(output, 'results.json'), auto_unbox = TRUE, pretty = TRUE)
if (length(failures)) stop('Activités en échec : ', paste(failures, collapse = ', '), call. = FALSE)
cat('Intégrité, colonnes et exécution des trousses vérifiées.\n')
