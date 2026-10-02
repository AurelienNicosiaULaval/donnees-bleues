# Contrôler les données, les filtres, les graphiques et les scripts exportés.
app_dir <- normalizePath("applications/explorer-maisons-quebec")
source(file.path(app_dir, "R/helpers.R"))
original <- read_houses(file.path(app_dir, "data/maisons-quebec.csv"))
stopifnot(identical(readBin(file.path(app_dir, "data/maisons-quebec.csv"), "raw", n = 1e6),
                   readBin("assets/data/maisons-quebec.csv", "raw", n = 1e6)))
summary <- house_summary(original)
stopifnot(summary$n == 600L, summary$value == 366000, summary$area == 107.65)
stopifnot(nrow(filter_houses(original, explorer_settings(types = "Jumelé"))) == 94L,
          nrow(filter_houses(original, explorer_settings(types = "Détaché"))) == 463L,
          nrow(filter_houses(original, explorer_settings(types = character()))) == 0L)
bad_variable <- tryCatch({explorer_settings(x = "inconnue"); FALSE}, error = function(e) TRUE)
stopifnot(bad_variable)
with_zero <- original
with_zero$aire_etages_m2[[1]] <- 0
stopifnot(nrow(plot_houses(with_zero, explorer_settings())) == 599L,
          grepl("1 ligne", plot_caption(with_zero, explorer_settings()), fixed = TRUE),
          nrow(plot_houses(with_zero, explorer_settings(log_axes = FALSE))) == 600L)

check_export <- function(graph, log_axes) {
  directory <- tempfile("explorer-export-")
  dir.create(directory)
  on.exit(unlink(directory, recursive = TRUE), add = TRUE)
  previous <- getwd()
  on.exit(setwd(previous), add = TRUE)
  file.copy(file.path(app_dir, "data/maisons-quebec.csv"),
    file.path(directory, "maisons-quebec.csv"))
  settings <- explorer_settings(types = c("Détaché", "Jumelé"),
    years = c(1950, 2000), graph = graph, log_axes = log_axes, bins = 17L)
  reference <- filter_houses(original, settings)
  stopifnot(nrow(reference) > 0L, all(reference$annee_construction >= 1950),
    all(reference$annee_construction <= 2000), !any(grepl("rangée", reference$lien_physique)))
  writeLines(export_house_code(settings), file.path(directory, "analyse.R"), useBytes = TRUE)
  setwd(directory)
  cairo_pdf("verification.pdf")
  on.exit(dev.off(), add = TRUE)
  environment <- new.env(parent = globalenv())
  trace("download.file", where = asNamespace("utils"),
    tracer = quote(stop("Téléchargement interdit pendant ce contrôle.")), print = FALSE)
  on.exit(untrace("download.file", where = asNamespace("utils")), add = TRUE)
  source("analyse.R", local = environment, encoding = "UTF-8")
  exported <- readr::read_csv("maisons-filtrees.csv", show_col_types = FALSE)
  stopifnot(identical(exported$maison_id, reference$maison_id),
    file.size("maisons-graphique.png") > 1000,
    isTRUE(all.equal(ggplot_build(environment$graphique)$data,
      ggplot_build(make_house_plot(reference, settings))$data, check.attributes = FALSE)))
}
for (graph in c("scatter", "histogram", "boxplot")) {
  for (log_axes in c(FALSE, TRUE)) check_export(graph, log_axes)
}
cat("600 maisons; filtres; exclusion logarithmique; 6 exports R et graphiques identiques : OK.\n")
