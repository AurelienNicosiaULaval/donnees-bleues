# Vérifier la version fixe sans modifier les tables du dépôt électoral.
# Depuis la racine de Données bleues :
# Rscript datasets/elections-quebec/verification.R [chemin-du-CSV]
library(readr)
library(dplyr)
library(yaml)
library(digest)

metadata <- read_yaml("datasets/elections-quebec/metadata.yml")
arguments <- commandArgs(trailingOnly = TRUE)
input <- if (length(arguments)) arguments[[1L]] else tempfile(fileext = ".csv")
if (!length(arguments)) {
  download.file(metadata$download_url, input, mode = "wb", quiet = TRUE)
}
stopifnot(digest(file = input, algo = "sha256") == metadata$verification$sha256)

results <- read_csv(
  input, col_types = cols(.default = col_character()),
  na = "NA", trim_ws = FALSE, show_col_types = FALSE
)
expected <- metadata$verification
stopifnot(
  nrow(results) == expected$rows, ncol(results) == expected$columns,
  n_distinct(results$snapshot_id) == expected$captures,
  !anyNA(results[c("election_id", "source_id", "candidate_id", "observed_at")]),
  !anyDuplicated(results[c("election_id", "source_id", "snapshot_id", "candidate_id")])
)

latest <- results |>
  group_by(election_id, source_id) |>
  filter(observed_at == max(observed_at)) |>
  ungroup()
stopifnot(
  nrow(latest) == expected$latest_rows,
  n_distinct(latest$district_id) == expected$latest_districts,
  all(latest$observed_at == expected$latest_observed_at),
  !anyDuplicated(latest$candidate_id),
  all(latest$data_status == expected$latest_status),
  all(latest$source_updated_at == expected$latest_source_updated_at),
  all(is.na(latest$elected_source)),
  !anyNA(latest$votes),
  sum(as.numeric(latest$votes)) == expected$latest_valid_votes
)
print(results |> count(observed_at, data_status, name = "resultats_par_capture"))
print(latest |> summarise(
  candidatures = n(), circonscriptions = n_distinct(district_id),
  votes_valides = sum(as.numeric(votes)),
  colonnes = ncol(latest)
))
message("Empreinte, dimensions, captures, clés, statut final et total des votes vérifiés.")
