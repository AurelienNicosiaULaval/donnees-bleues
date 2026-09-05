# These two sources are acquired for execution only and are never public artifacts.
source('R/utils_classroom.R')
root <- normalizePath('.')
acquire <- '--acquire' %in% commandArgs(trailingOnly = TRUE)
verify_source_kit <- function(id) {
  stage <- root
  library_env <- paste0('R_LIBS=', shQuote(paste(.libPaths(), collapse = .Platform$path.sep)))
  if (acquire) {
    stage <- tempfile(paste0('source-kit-', id, '-'))
    dir.create(stage)
    on.exit(unlink(stage, recursive = TRUE), add = TRUE)
    archive <- file.path(root, 'assets/classroom', paste0(id, '.zip'))
    receipt <- jsonlite::read_json(paste0(archive, '.json'))
    stopifnot(classroom_sha(archive) == receipt$archive_sha256)
    utils::unzip(archive, exdir = stage)
    output <- file.path(root, 'data/validation/source-activities', id)
    dir.create(output, recursive = TRUE, showWarnings = FALSE)
    code <- paste0('setwd(', encodeString(stage, quote = '"'),
                   '); Sys.setenv(DB_OFFLINE = "false"); source("preparer-donnees.R")')
    status <- system2(file.path(R.home('bin'), 'Rscript'), c('--vanilla', '-e', shQuote(code)),
      stdout = file.path(output, 'acquisition.log'), stderr = file.path(output, 'acquisition.log'),
      env = library_env)
    if (status != 0L) stop('Acquisition depuis la trousse en échec : ', id)
  }
  for (script in classroom_script_paths(id)) {
    output <- file.path(root, 'data/validation/source-activities', id, tools::file_path_sans_ext(basename(script)))
    dir.create(output, recursive = TRUE, showWarnings = FALSE)
    arguments <- vapply(c(file.path(root, 'scripts/run_activity.R'),
      file.path(stage, script), output, stage), shQuote, character(1))
    status <- system2(file.path(R.home('bin'), 'Rscript'), arguments,
      stdout = file.path(output, 'run.log'), stderr = file.path(output, 'run.log'), env = library_env)
    if (status != 0L) stop('Activité avec acquisition en échec : ', script)
    cat(script, ': vérifiée sur les données acquises.\n')
  }
}
for (id in c('cohortes-diplomation', 'emploi-regional-quebec')) verify_source_kit(id)
