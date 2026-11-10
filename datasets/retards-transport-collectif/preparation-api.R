# Résumer l'accès documenté aux ressources, sans inventer de données de retard.
library(dplyr)
library(jsonlite)
preparer_retards_api <- function(fichier) {
  reponse <- jsonlite::read_json(fichier)
  if (!isTRUE(reponse$success) || !identical(reponse$result$name, 'vmtl-stm-bus-temps-reel-gtfs-realtime'))
    stop('Métadonnées CKAN invalides.', call. = FALSE)
  ressources <- reponse$result$resources
  if (!length(ressources)) stop('Aucune ressource de transport documentée.', call. = FALSE)
  nettoyer <- function(x) if (is.null(x) || !length(x)) '' else as.character(x[[1]])
  formats <- vapply(ressources, function(x) nettoyer(x$format), character(1))
  urls <- vapply(ressources, function(x) nettoyer(x$url), character(1))
  descriptions <- vapply(ressources, function(x) nettoyer(x$description), character(1))
  portail <- grepl('d[ée]veloppeur|developer', paste(urls, descriptions), ignore.case = TRUE)
  fichier_direct <- grepl('[.](csv|json|zip|geojson|xlsx|pb)([?]|$)', urls, ignore.case = TRUE)
  tibble::tibble(n_resources_ckan = length(ressources), n_gtfs_resources = sum(grepl('GTFS', formats, ignore.case = TRUE)),
    n_developer_portal_resources = sum(portail), n_direct_download_resources = sum(fichier_direct & !portail),
    source_requires_developer_account = if (any(portail)) TRUE else NA)
}
