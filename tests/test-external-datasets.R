# External contributions must be discoverable without implying a local teaching kit.
source("R/utils_classroom.R")
source("R/utils_resources.R")
source("R/utils_dataset_page.R")

local({
  metadata <- yaml::read_yaml("datasets/hydro-quebec-temperature/metadata.yml")
  stopifnot(classroom_policy(metadata)$mode == "external")
  fails <- function(expression) inherits(tryCatch(force(expression), error = identity), "error")
  bad <- metadata
  bad$publication$preview <- TRUE
  stopifnot(fails(classroom_policy(bad)))
  bad <- metadata
  bad$download_url <- NULL
  stopifnot(fails(classroom_policy(bad)))
  bad <- metadata
  bad$publication$classroom$files <- list(list(path = "data.csv", columns = "value"))
  stopifnot(fails(classroom_policy(bad)), fails(build_classroom_kit(metadata)))
  stopifnot(editorial_license(metadata$license) == "Licences distinctes selon les fichiers",
            editorial_license("Données ECCC") == "Licence d’ECCC",
            editorial_license("CC BY-NC 4.0") == "CC BY-NC")

  original_context <- dataset_current_context
  on.exit(assign("dataset_current_context", original_context, envir = .GlobalEnv))
  assign("dataset_current_context", function() list(root = ".", relative_root = "../..",
    dataset_dir = "datasets/hydro-quebec-temperature"), envir = .GlobalEnv)
  html <- paste(capture.output({render_dataset_detail_header(); render_dataset_detail_footer()}), collapse = "\n")
  doc <- xml2::read_html(html)
  links <- xml2::xml_attr(xml2::xml_find_all(doc, "//a"), "href")
  stopifnot(metadata$download_url %in% links,
            !any(grepl("assets/classroom", links)),
            !any(grepl("activites-pedagogiques", links)),
            grepl("Julien Miron", xml2::xml_text(doc), fixed = TRUE))
  item <- Filter(function(x) x$id == "donnees-hydro-quebec-temperature", resource_catalogue())
  stopifnot(length(item) == 1L, item[[1L]]$contributor == "Julien Miron",
            "Hydro-Québec" %in% item[[1L]]$authors, !length(item[[1L]]$courses))
})
message("Fiche externe : accès, crédits, licences et absence de trousse vérifiés.")
