# Each existing resource remains indexed; course use must be explicit.
source("R/utils_resources.R")
resource_test_items <- resource_catalogue()
resource_test_ids <- vapply(resource_test_items, function(x) x$id, character(1))
stopifnot(!anyDuplicated(resource_test_ids))
stopifnot(length(resource_test_items) == nrow(readr::read_csv("data/metadata/catalogue.csv", show_col_types = FALSE)) +
  nrow(readr::read_csv("data/metadata/catalogue_activites.csv", show_col_types = FALSE)) + length(resource_extra()))
stopifnot(all(vapply(resource_test_items, function(x) file.exists(sub("[.]html$", ".qmd", x$url)), logical(1))))
resource_test_bixi <- Filter(function(x) x$id == "tutoriel-bixi", resource_test_items)[[1]]
stopifnot(length(resource_test_bixi$courses) == 2,
  any(grepl("STT-4230", resource_test_bixi$courses)), any(grepl("STT-6230", resource_test_bixi$courses)))
stopifnot(resource_escape('<script>"&') == '&lt;script&gt;&quot;&amp;')
rm(resource_test_items, resource_test_ids, resource_test_bixi)
