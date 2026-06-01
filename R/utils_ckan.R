ckan_action <- function(action, query = list(), base_url = "https://www.donneesquebec.ca/recherche") {
  if (!requireNamespace("httr2", quietly = TRUE)) {
    stop("Le package httr2 est requis.", call. = FALSE)
  }

  endpoint <- paste0(gsub("/+$", "", base_url), "/api/3/action/", action)
  request <- httr2::request(endpoint)

  if (length(query) > 0L) {
    request <- do.call(httr2::req_url_query, c(list(request), query))
  }

  response <- httr2::req_perform(request)
  payload <- httr2::resp_body_json(response, simplifyVector = TRUE)

  if (!isTRUE(payload$success)) {
    error_message <- payload$error$message
    if (is.null(error_message)) {
      error_message <- paste("Erreur CKAN pour l'action", action)
    }
    stop(error_message, call. = FALSE)
  }

  payload$result
}

ckan_package_search <- function(q, rows = 10, start = 0, base_url = "https://www.donneesquebec.ca/recherche") {
  ckan_action(
    "package_search",
    query = list(q = q, rows = rows, start = start),
    base_url = base_url
  )
}

ckan_package_show <- function(id, base_url = "https://www.donneesquebec.ca/recherche") {
  ckan_action(
    "package_show",
    query = list(id = id),
    base_url = base_url
  )
}

ckan_resource_show <- function(id, base_url = "https://www.donneesquebec.ca/recherche") {
  ckan_action(
    "resource_show",
    query = list(id = id),
    base_url = base_url
  )
}

