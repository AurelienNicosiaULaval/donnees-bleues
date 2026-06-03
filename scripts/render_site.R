source("R/utils_catalogue.R")
source("R/utils_activities.R")

catalogue <- build_catalogue("datasets")
write_catalogue(catalogue, "data/metadata/catalogue.csv")
saveRDS(catalogue, "data/metadata/catalogue.rds")

catalogue_activites <- build_activity_catalogue("datasets")
validate_activity_catalogue(catalogue_activites)
write_activity_catalogue(catalogue_activites, "data/metadata/catalogue_activites.csv")
saveRDS(catalogue_activites, "data/metadata/catalogue_activites.rds")

status <- system2("quarto", c("render"), stdout = TRUE, stderr = TRUE)
cat(paste(status, collapse = "\n"), "\n")

exit_code <- attr(status, "status")
if (!is.null(exit_code) && exit_code != 0) {
  stop("Le rendu Quarto a échoué.", call. = FALSE)
}
