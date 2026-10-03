# Acquisition préalable : Rscript datasets/rapports-accident/preparation.R.
# Cette étape locale ne télécharge rien; elle fige seulement les champs déclarés.
library(readr)
library(dplyr)
library(jsonlite)
library(digest)
path <- "data/processed/rapports-accident/rapports_accident_2022_prepares.csv"
manifest <- read_json("data/processed/rapports-accident/manifest.json")
data <- read_csv(path, show_col_types = FALSE,
  col_types = cols(.default = col_character())) |>
  select(annee, jour_semaine_code, gravite)
stopifnot(nrow(data) == 108186L, all(data$annee == "2022"),
  !anyNA(data), all(data$jour_semaine_code %in% c("SEM", "FDS")))
source_csv <- Filter(function(x) x$file == "Rapport_Accident_2022.csv", manifest$sources)
stopifnot(length(source_csv) == 1L,
  source_csv[[1L]]$sha256 == "17fc60a26fb8ed8cc0fac871a7e4efc30cda95b93500e7a7f8213ba45008232a")
dir.create("assets/data", showWarnings = FALSE)
write_csv(data, "assets/data/accidents-quebec-2022.csv")
write_json(list(version = "1.0.0", dataset = "rapports-accident", rows = nrow(data),
  columns = names(data), source = source_csv[[1L]], prepared_at_utc = manifest$prepared_at_utc,
  sha256 = digest(file = "assets/data/accidents-quebec-2022.csv", algo = "sha256")),
  "assets/data/accidents-quebec-2022.json", auto_unbox = TRUE, pretty = TRUE)
