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

phase_arg <- arg_value(args, "--phase", "core,ges")
phases <- normalize_ulaval_phases(phase_arg)

report <- validate_ulaval_private_source(
  root = ".",
  source_path = source_path,
  phases = phases,
  require_source = TRUE
)

print(report, row.names = FALSE)
message("Validation ULaval réussie.")
