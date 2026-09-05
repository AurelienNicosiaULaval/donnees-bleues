library(readr)
library(yaml)
source("R/utils_publication.R")
source("R/utils_dataset_charts.R")
expect_error <- function(expression, pattern) {
  message <- tryCatch({ force(expression); NA_character_ }, error = function(e) conditionMessage(e))
  if (is.na(message) || !grepl(pattern, message)) stop("Erreur attendue : ", pattern)
}
metadata <- read_yaml("datasets/bixi/metadata.yml")
data <- validate_public_preview(metadata)
validate_chart_spec(data, metadata$chart)
bad_spec <- metadata$chart
bad_spec$x_variable <- "identifiant_inexistant"
expect_error(validate_chart_spec(data, bad_spec), "Variable graphique absente")
bad_spec$type <- "line"
expect_error(validate_chart_spec(data, bad_spec), "Type de graphique")
temporary <- tempfile(fileext = ".csv")
write_csv(transform(data, colonne_non_autorisee = "test"), temporary)
expect_error(validate_public_preview(metadata, temporary), "colonnes")
restricted <- read_yaml("datasets/emploi-regional-quebec/metadata.yml")
expect_error(validate_public_preview(restricted, temporary), "décision négative")
unlink(temporary)
message("Publication : ajout de colonne, publication interdite et graphique incohérent détectés.")
