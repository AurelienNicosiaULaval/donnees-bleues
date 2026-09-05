source("R/utils_classroom.R")
# A dataset may supply one activity; all declared activities must remain discoverable.
local({
  root <- tempfile("activity-discovery-")
  dir.create(file.path(root, "example"), recursive = TRUE)
  on.exit(unlink(root, recursive = TRUE))
  writeLines("id: first", file.path(root, "example", "activite-courte.yml"))
  writeLines("# helper", file.path(root, "example", "helper.R"))
  stopifnot(identical(classroom_script_paths("example", root),
    file.path(root, "example", "activite-courte.R")))
  writeLines("id: second", file.path(root, "example", "activite-longue.yml"))
  stopifnot(length(classroom_script_paths("example", root)) == 2L)
  empty <- tryCatch({classroom_script_paths("missing", root); FALSE}, error = function(e) TRUE)
  stopifnot(empty)
})
# Check the shipped tree sample, including string identifiers and the source fingerprint.
local({
  metadata <- yaml::read_yaml("datasets/arbres-quebec/metadata.yml")
  stopifnot(length(classroom_script_paths(metadata$id)) == 1L)
  archive <- "assets/classroom/arbres-quebec.zip"
  receipt <- jsonlite::read_json(paste0(archive, ".json"))
  stopifnot(classroom_sha(archive) == receipt$archive_sha256,
    receipt$tables[[1]]$prepared_table_sha256 ==
      "1af11ff0fc824f35286987928f0423441540ece1badb674f347ab05db07d4ccf")
  stage <- tempfile("arbres-test-"); dir.create(stage)
  on.exit(unlink(stage, recursive = TRUE))
  entries <- utils::unzip(archive, exdir = stage)
  for (notice in unlist(metadata$publication$classroom$notices)) {
    stopifnot(file.exists(file.path(stage, notice)),
      classroom_sha(notice) == classroom_sha(file.path(stage, notice)))
  }
  data <- readr::read_csv(file.path(stage, metadata$processed_file),
    col_types = readr::cols(.default = readr::col_guess(), plot_id = readr::col_character(),
      tree_id = readr::col_character(), record_id = readr::col_character()), show_col_types = FALSE)
  stopifnot(nrow(data) == 200, ncol(data) == 21, is.character(data$plot_id),
    length(unique(data$plot_id)) == 200, all(table(data$species) == 50),
    sum(is.na(data$age_years)) == 52,
    all(is.na(data$age_years[data$species_code == "ERR"])),
    !anyNA(data$diameter_cm), !anyNA(data$height_m),
    max(abs(data$basal_area_m2 - pi * (data$diameter_cm / 200)^2)) < 1e-12)
})
message("Activité unique et trousse Arbres du Québec : vérifiées.")
