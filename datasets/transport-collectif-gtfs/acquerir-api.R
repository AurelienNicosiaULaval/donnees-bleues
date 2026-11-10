# Résoudre la ressource GTFS par l'API Données Québec, puis garder le fichier RTC daté.
library(jsonlite)
library(curl)
library(digest)
source('R/utils_downloads.R')
acquerir_gtfs_api <- function(dossier) {
  if (dir.exists(dossier)) stop('Choisir un nouveau dossier de collecte.', call.=FALSE)
  dir.create(dossier,recursive=TRUE)
  package_url <- 'https://www.donneesquebec.ca/recherche/api/3/action/package_show?id=rtc-gtfs-arrets-et-les-parcours'
  metadata <- file.path(dossier,'package-api.json')
  download_source(package_url,metadata)
  paquet <- jsonlite::read_json(metadata)
  if (!isTRUE(paquet$success) || !identical(paquet$result$name,'rtc-gtfs-arrets-et-les-parcours'))
    stop('Métadonnées Données Québec invalides.',call.=FALSE)
  resultat <- Filter(function(x) identical(x$id,'52f3e1db-992b-42ac-87b9-bb4be1de6111'),paquet$result$resources)
  if (length(resultat)!=1L || !identical(toupper(resultat[[1]]$format),'GTFS'))
    stop('Ressource GTFS absente ou ambiguë.',call.=FALSE)
  url <- resultat[[1]]$url
  if (!identical(url,'https://cdn.rtcquebec.ca/Site_Internet/DonneesOuvertes/googletransit.zip'))
    stop('Adresse GTFS modifiée; vérifier la source avant une nouvelle acquisition.',call.=FALSE)
  fichier <- file.path(dossier,'gtfs-rtc.zip')
  temporaire <- tempfile(tmpdir=dossier);on.exit(unlink(temporaire),add=TRUE)
  debut <- source_timestamp()
  h <- curl::new_handle(followlocation=TRUE,timeout=180)
  reponse <- curl::curl_fetch_disk(url,temporaire,handle=h)
  if (reponse$status_code!=200L || !identical(reponse$url,url) || !file.exists(temporaire))
    stop('Téléchargement GTFS invalide.',call.=FALSE)
  entetes <- curl::parse_headers_list(reponse$headers)
  modifie <- entetes[['last-modified']]
  if (is.null(modifie) || length(modifie)!=1L) stop('Date de mise à jour RTC absente.',call.=FALSE)
  instant <- curl::parse_date(modifie)
  if (length(instant)!=1L || is.na(instant)) stop('Date de mise à jour RTC illisible.',call.=FALSE)
  if (!file.rename(temporaire,fichier)) stop('Impossible de conserver le GTFS.',call.=FALSE)
  record_source(fichier,url,kind='gtfs_identifie_par_api',started_at=debut,
    details=list(resource_id=resultat[[1]]$id, last_modified_http=modifie,
      rtc_updated_date=format(instant,'%Y-%m-%d',tz='UTC'), etag=entetes[['etag']]))
  invisible(list(metadata=metadata,gtfs=fichier))
}
