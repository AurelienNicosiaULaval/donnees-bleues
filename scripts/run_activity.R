# Execute one activity in an isolated process with downloads disabled.
args <- commandArgs(trailingOnly = TRUE)
script <- normalizePath(args[[1]], mustWork = TRUE)
output <- args[[2]]
dir.create(output, recursive = TRUE, showWarnings = FALSE)
output <- normalizePath(output)
if (length(args) >= 3L) setwd(args[[3]])
trace('download.file', where = asNamespace('utils'),
      tracer = quote(stop('Téléchargement interdit dans le test de classe.')), print = FALSE)
for (name in c('curl_download', 'curl_fetch_memory', 'curl_fetch_disk', 'curl_fetch_stream')) {
  trace(name, where = asNamespace('curl'),
        tracer = quote(stop('Connexion interdite dans le test de classe.')), print = FALSE)
}
Sys.setenv(DB_OFFLINE = 'true')
env <- new.env(parent = globalenv())
warnings <- character()
status <- 'ok'; failure <- NULL; tables <- 0L; plots <- 0L
# Cairo preserves French accents and avoids device-specific text substitution.
if (capabilities('cairo')) grDevices::cairo_pdf(file.path(output, 'figures.pdf'), width = 10, height = 7) else
  grDevices::pdf(file.path(output, 'figures.pdf'), width = 10, height = 7)
tryCatch(withCallingHandlers({
  for (expression in parse(script)) {
    result <- withVisible(eval(expression, envir = env))
    value <- result$value
    if (inherits(value, 'ggplot')) {
      layers <- ggplot2::ggplot_build(value)$data
      if (!any(vapply(layers, nrow, integer(1)) > 0L)) stop('Graphique sans observation.')
      plots <- plots + 1L
    }
    if (is.data.frame(value)) tables <- tables + 1L
    # Scripts print their own outputs, just as with the RStudio Source button.
  }
}, warning = function(w) {
  message <- conditionMessage(w)
  warnings <<- c(warnings, message)
  if (!grepl('was built under R version', message)) stop(message, call. = FALSE)
  invokeRestart('muffleWarning')
}), error = function(e) {status <<- 'error'; failure <<- conditionMessage(e)})
grDevices::dev.off()
jsonlite::write_json(list(script = basename(script), status = status, error = failure,
  tables = tables, plots = plots, warnings = unique(warnings)),
  file.path(output, 'result.json'), auto_unbox = TRUE, pretty = TRUE)
if (status != 'ok') stop(failure, call. = FALSE)
