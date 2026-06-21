source("R/utils_catalogue.R")
source("R/utils_activities.R")
source("R/utils_card_images.R")

run_quarto <- function(args) {
  status <- system2("quarto", args, stdout = TRUE, stderr = TRUE)
  cat(paste(status, collapse = "\n"), "\n")

  exit_code <- attr(status, "status")
  if (!is.null(exit_code) && exit_code != 0) {
    stop(
      paste("Le rendu Quarto a échoué pour:", paste(args, collapse = " ")),
      call. = FALSE
    )
  }
}

site_inputs <- function() {
  root_pages <- c(
    "index.qmd",
    "catalogue.qmd",
    "zero-waste.qmd",
    "activites.qmd",
    "about.qmd",
    "contribuer.qmd",
    "references.qmd",
    "credits-images.qmd",
    "donnees-ulaval.qmd"
  )

  nested_pages <- c(
    list.files("activities", pattern = "[.]qmd$", recursive = TRUE, full.names = TRUE),
    list.files("datasets", pattern = "[.]qmd$", recursive = TRUE, full.names = TRUE)
  )

  c(root_pages[file.exists(root_pages)], sort(nested_pages))
}

catalogue <- build_catalogue("datasets")
validate_card_images(catalogue)
write_catalogue(catalogue, "data/metadata/catalogue.csv")
saveRDS(catalogue, "data/metadata/catalogue.rds")

catalogue_activites <- build_activity_catalogue("datasets")
validate_activity_catalogue(catalogue_activites)
write_activity_catalogue(catalogue_activites, "data/metadata/catalogue_activites.csv")
saveRDS(catalogue_activites, "data/metadata/catalogue_activites.rds")

for (input in site_inputs()) {
  run_quarto(c("render", input, "--no-clean"))
}
