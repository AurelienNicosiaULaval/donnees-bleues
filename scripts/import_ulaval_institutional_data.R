source("R/utils_ulaval.R")

arg_value <- function(args, name, default = NULL) {
  prefix <- paste0(name, "=")
  value <- args[startsWith(args, prefix)]
  if (length(value) == 0L) {
    return(default)
  }
  sub(prefix, "", value[[length(value)]], fixed = TRUE)
}

args <- commandArgs(trailingOnly = TRUE)

source_path <- arg_value(args, "--source", Sys.getenv("DONNEES_ULAVAL_SOURCE", unset = ""))
if (!nzchar(source_path)) {
  source_path <- NULL
}

output_dir <- arg_value(args, "--output", file.path("data", "processed", "ulaval"))
phase_arg <- arg_value(args, "--phase", "core")
phases <- normalize_ulaval_phases(phase_arg)

copied <- import_ulaval_datasets(
  root = ".",
  source_path = source_path,
  output_dir = output_dir,
  phases = phases
)

message("Importation ULaval terminée.")
message("Source canonique : ", find_ulaval_source(".", source_path, require_source = TRUE))
message("Sortie locale ignorée par Git : ", normalizePath(output_dir, mustWork = FALSE))
message("Fichiers copiés : ", length(copied))
