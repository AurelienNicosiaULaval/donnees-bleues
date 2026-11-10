# Usage : Rscript --vanilla scripts/collect_donnees_quebec.R
# Réactualise uniquement la documentation; aucun CSV pédagogique n'est remplacé.
library(httr2)
library(xml2)
library(jsonlite)
library(readr)
source('R/utils_donnees_quebec.R')

inventory <- dq_inventory()
dir.create('data/validation/donnees-quebec', recursive = TRUE, showWarnings = FALSE)
write_csv(inventory, 'data/validation/donnees-quebec/occurrences.csv')
ids <- unique(inventory$requested_id)
sources <- list()
previous <- if ('--reuse-verified' %in% commandArgs(trailingOnly = TRUE) &&
  file.exists('data/metadata/donnees_quebec.json')) dq_read_registry() else NULL
for (id in ids) {
  url <- paste0('https://www.donneesquebec.ca/recherche/dataset/', id)
  message('Documentation : ', id)
  result <- tryCatch({
    cached <- Filter(function(x) id %in% unlist(x$aliases) && identical(x$status, 'verified'), previous$sources)
    if (length(cached) == 1L && identical(previous$verified_on, as.character(Sys.Date()))) {
      saved <- cached[[1]]
      saved$dataset_ids <- unique(inventory$dataset_id[inventory$requested_id == id])
      saved$aliases <- id
      saved
    } else {
    api_url <- paste0('https://www.donneesquebec.ca/recherche/api/3/action/package_show?id=', id)
    api <- request(api_url) |> req_timeout(30) |> req_retry(max_tries = 2) |> req_perform() |> resp_body_json()
    if (!isTRUE(api$success)) stop('API : success différent de true.')
    package <- api$result
    page_url <- paste0('https://www.donneesquebec.ca/recherche/dataset/', package$name)
    response <- request(page_url) |> req_timeout(30) |> req_retry(max_tries = 2) |> req_perform()
    html <- resp_body_string(response)
    node <- xml_find_first(read_html(html), '//*[@id="citation"]')
    citation <- trimws(gsub('[[:space:]]+', ' ', xml_text(node)))
    if (is.na(citation) || !nzchar(citation) || !grepl(page_url, citation, fixed = TRUE))
      stop('Citation officielle absente ou page protégée.')
    evidence <- file.path('data/validation/donnees-quebec', paste0(package$name, '.html'))
    writeLines(html, evidence, useBytes = TRUE)
    list(status = 'verified', requested_url = url, aliases = id, package_id = package$id,
      package_name = package$name, page_url = page_url, title = package$title,
      citation = citation, verified_at_utc = format(Sys.time(), '%Y-%m-%dT%H:%M:%SZ', tz = 'UTC'),
      page_sha256 = digest::digest(file = evidence, algo = 'sha256'),
      license_title = package$license_title, license_url = package$license_url,
      metadata_modified = package$metadata_modified,
      resources = lapply(package$resources, function(x) x[c('id', 'name', 'format', 'url', 'datastore_active')]),
      dataset_ids = unique(inventory$dataset_id[inventory$requested_id == id]))
    }
  }, error = function(e) list(status = 'unverified', requested_url = url, aliases = id,
    error = conditionMessage(e), dataset_ids = unique(inventory$dataset_id[inventory$requested_id == id])))
  key <- result$package_id %||dq% id
  if (!is.null(sources[[key]])) {
    result$aliases <- unique(c(unlist(sources[[key]]$aliases), id))
    result$dataset_ids <- unique(c(unlist(sources[[key]]$dataset_ids), unlist(result$dataset_ids)))
  }
  sources[[key]] <- result
}
registry <- list(schema_version = 1L, verified_on = as.character(Sys.Date()),
  attribution_guidance = 'https://www.donneesquebec.ca/licence/meilleures-pratiques-pour-donner-le-credit-dun-jeu/',
  api_documentation = 'https://www.donneesquebec.ca/page-api/', sources = unname(sources))
write_json(registry, 'data/metadata/donnees_quebec.json', pretty = TRUE, auto_unbox = TRUE, null = 'null')
summary <- do.call(rbind, lapply(registry$sources, function(x) data.frame(
  dataset_ids = paste(unlist(x$dataset_ids), collapse = ';'), source = x$page_url %||dq% x$requested_url,
  status = x$status, resources = length(x$resources),
  datastore_resources = sum(vapply(x$resources, function(r) isTRUE(r$datastore_active), logical(1))),
  error = x$error %||dq% '')))
write_csv(summary, 'data/validation/donnees-quebec/inventaire.csv')
print(summary[, c('dataset_ids', 'status', 'datastore_resources', 'error')], row.names = FALSE)
if (any(summary$status != 'verified')) stop('Certaines références restent à vérifier; voir l’inventaire.', call. = FALSE)
