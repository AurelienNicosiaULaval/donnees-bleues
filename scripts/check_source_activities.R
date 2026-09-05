# These two sources are acquired for execution only and are never public artifacts.
source('R/utils_classroom.R')
root <- normalizePath('.')
for (id in c('cohortes-diplomation', 'emploi-regional-quebec')) {
  for (script in classroom_script_paths(id)) {
    output <- file.path(root, 'data/validation/source-activities', id, tools::file_path_sans_ext(basename(script)))
    dir.create(output, recursive = TRUE, showWarnings = FALSE)
    arguments <- vapply(c('scripts/run_activity.R', normalizePath(script), output, root), shQuote, character(1))
    status <- system2(file.path(R.home('bin'), 'Rscript'), arguments,
      stdout = file.path(output, 'run.log'), stderr = file.path(output, 'run.log'))
    if (status != 0L) stop('Activité avec acquisition en échec : ', script)
    cat(script, ': vérifiée sur les données acquises.\n')
  }
}
