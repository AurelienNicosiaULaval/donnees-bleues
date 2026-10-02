# From RStudio: open this directory as your project and source this file.
# From a terminal: Rscript /absolute/path/to/LANCER.R
library(shiny)
args <- commandArgs(trailingOnly = FALSE)
file_arg <- args[startsWith(args, "--file=")]
app_dir <- if (length(file_arg)) {
  dirname(normalizePath(sub("^--file=", "", file_arg[1]), mustWork = TRUE))
} else getwd()
stopifnot(file.exists(file.path(app_dir, "app.R")))
runApp(app_dir, launch.browser = interactive())
