source("R/utils_catalogue.R")
source("R/utils_activities.R")
source("R/utils_card_images.R")
source("R/utils_site_validation.R")

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

clear_quarto_session_artifacts <- function() {
  if (dir.exists(".quarto")) unlink(".quarto", recursive = TRUE, force = TRUE)
  if (dir.exists("site_libs")) unlink("site_libs", recursive = TRUE, force = TRUE)
  invisible(TRUE)
}

site_inputs <- function() {
  root_pages <- c(
    "index.qmd",
    "catalogue.qmd",
    "ressources.qmd",
    "zero-waste.qmd",
    "activites.qmd",
    "about.qmd",
    "contribuer.qmd",
    "retours-classe.qmd",
    "sequences.qmd",
    "references.qmd",
    "credits-images.qmd",
    "donnees-ulaval.qmd"
  )

  nested_pages <- c(
    list.files("resources", pattern = "[.]qmd$", recursive = TRUE, full.names = TRUE),
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
validate_activity_resources(catalogue_activites)
validate_activity_contract_renderers(catalogue_activites)
validate_documented_paths()
write_activity_catalogue(catalogue_activites, "data/metadata/catalogue_activites.csv")
saveRDS(catalogue_activites, "data/metadata/catalogue_activites.rds")

for (input in site_inputs()) {
  clear_quarto_session_artifacts()
  run_quarto(c("render", input, "--execute", "--no-cache", "--no-clean"))
}

postprocess_site_headings("docs")
