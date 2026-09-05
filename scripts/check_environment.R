lock <- jsonlite::read_json('renv.lock')
stopifnot(as.character(getRversion()) == lock$R$Version)
for (name in names(lock$Packages)) {
  if (!requireNamespace(name, quietly = TRUE) ||
      utils::packageVersion(name) != package_version(lock$Packages[[name]]$Version)) {
    stop('Version de package différente du verrou : ', name, call. = FALSE)
  }
}
quarto_version <- system2('quarto', '--version', stdout = TRUE)
stopifnot(identical(trimws(quarto_version), '1.9.38'))
cat('R, Quarto et les packages correspondent aux versions déclarées.\n')
