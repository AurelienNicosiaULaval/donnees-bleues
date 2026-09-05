source("R/utils_taxonomy.R")
stopifnot(identical(taxonomy_resolve(c("Visualisation", "visualisation")), rep("visualisation", 2)),
          identical(taxonomy_resolve(c("Statistique descriptive", "statistiques descriptives")), rep("statistiques-descriptives", 2)),
          identical(taxonomy_resolve(c("Introductif", "Introduction"), "levels"), rep("introduction", 2)))
paths <- list.files("datasets", pattern = "[.]yml$", full.names = TRUE, recursive = TRUE)
for (path in paths) validate_taxonomy_metadata(yaml::read_yaml(path))
message("Taxonomie validée sur toutes les fiches et activités.")
