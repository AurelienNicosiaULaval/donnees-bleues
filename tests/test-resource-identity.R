# Dates must be real, ordered and present for every catalogue entry.
source("R/utils_resources.R")
items <- resource_catalogue()
invisible(lapply(items, validate_resource_dates))
stopifnot(setequal(vapply(items, function(x) x$type, character(1)),
                   c("donnees", "activite", "document", "application")))
good <- list(id = "date-test", date_added = "2026-06-01", date_updated = "2026-09-05")
bad_dates <- list(
  within(good, date_added <- NULL),
  within(good, date_added <- c("2026-06-01", "2026-06-02")),
  within(good, date_updated <- "2026-02-30"),
  within(good, date_updated <- "2026-05-31"),
  within(good, date_updated <- "05/09/2026"),
  within(good, date_updated <- as.character(Sys.Date() + 1L))
)
for (bad in bad_dates) {
  rejected <- tryCatch({validate_resource_dates(bad); FALSE}, error = function(e) TRUE)
  stopifnot(rejected)
}
# Neither an unlabelled colour nor a source access date can stand in for the identity.
for (type in unique(vapply(items, function(x) x$type, character(1)))) {
  badge <- xml2::read_html(resource_type_badge(type))
  stopifnot(length(xml2::xml_find_all(badge, "//svg[@aria-hidden='true']")) == 1L,
            nzchar(xml2::xml_text(xml2::xml_find_first(badge, "//span/span"))))
}
rendered <- paste(capture.output(render_resource_cards()), collapse = "\n")
cards <- xml2::xml_find_all(xml2::read_html(rendered), "//article")
stopifnot(length(cards) == length(items))
for (i in seq_along(items)) {
  dates <- c(xml2::xml_attr(cards[[i]], "data-date-added"), xml2::xml_attr(cards[[i]], "data-date-updated"))
  stopifnot(identical(dates, c(items[[i]]$date_added, items[[i]]$date_updated)))
}
message(length(items), " ressources : dates valides, badges lisibles et recherche cohérente.")
