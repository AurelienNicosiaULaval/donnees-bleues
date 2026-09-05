library(ggplot2)
library(readr)
library(yaml)
source("R/utils_publication.R")
source("R/utils_dataset_charts.R")
dir.create("assets/charts", recursive = TRUE, showWarnings = FALSE)
paths <- list.files("datasets", pattern = "metadata.yml$", recursive = TRUE, full.names = TRUE)
for (path in paths) {
  metadata <- read_yaml(path)
  validate_publication_policy(metadata)
  if (!isTRUE(metadata$publication$preview)) next
  data <- validate_public_preview(metadata)
  chart <- build_dataset_chart(data, metadata)
  output <- file.path("assets/charts", paste0(metadata$id, ".svg"))
  ggsave(output, chart, width = 8, height = if (metadata$chart$type == "pyramid") 7 else 5, device = svglite::svglite)
  message("Graphique : ", metadata$id)
}
