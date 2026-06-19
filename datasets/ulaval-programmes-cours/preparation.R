source("R/utils_ulaval.R")

phases <- "core"
include_ges <- tolower(Sys.getenv("DONNEES_ULAVAL_INCLUDE_GES", unset = "false"))

if (include_ges %in% c("1", "true", "yes", "oui")) {
  phases <- c("core", "ges")
}

copied <- import_ulaval_datasets(
  root = ".",
  phases = phases
)

message("Fichiers ULaval copiés localement : ", length(copied))
message("Aucun PDF source n'a été copié.")
