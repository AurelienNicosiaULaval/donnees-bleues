# Conserver les arrêts préparés, les sources et la mention de provenance exigée par le RTC.
library(readr)
library(jsonlite)
library(digest)
enregistrer_gtfs_api <- function(metadata,gtfs,dossier) {
  table <- preparer_gtfs_api(gtfs)
  recu <- jsonlite::read_json(paste0(gtfs,'.source.json'))
  source_meta <- jsonlite::read_json(paste0(metadata,'.source.json'))
  if (is.null(recu$details$rtc_updated_date) || !nzchar(recu$details$rtc_updated_date))
    stop('Date de mise à jour RTC absente.',call.=FALSE)
  dir.create(dossier,recursive=TRUE,showWarnings=FALSE)
  sortie <- file.path(dossier,'table-activite.csv')
  candidat <- tempfile(tmpdir=dossier);on.exit(unlink(candidat),add=TRUE)
  readr::write_csv(table,candidat,na='NA')
  if (file.exists(sortie)) {
    if (!identical(digest::digest(file=candidat,algo='sha256'),digest::digest(file=sortie,algo='sha256')))
      stop('La table existante diffère de cette reconstruction.',call.=FALSE)
  } else if (!file.rename(candidat,sortie)) stop('Impossible de conserver la table.',call.=FALSE)
  attribution <- paste0('Produit intégrant les informations publiques du Réseau de transport de la Capitale, mises à jour le ',
    recu$details$rtc_updated_date, '. Source et conditions : https://www.rtcquebec.ca/donnees-ouvertes')
  writeLines(attribution,file.path(dossier,'CITATION-RTC.txt'),useBytes=TRUE)
  jsonlite::write_json(list(source_donnees_quebec=source_meta,source_gtfs=recu,
    sha256_prepare=digest::digest(file=sortie,algo='sha256'),
    sha256_preparation=digest::digest(file='datasets/transport-collectif-gtfs/preparation-api.R',algo='sha256'),
    lignes=nrow(table),colonnes=names(table),attribution_rtc=attribution),
    file.path(dossier,'preparation.json'),auto_unbox=TRUE,pretty=TRUE)
  Sys.setenv(DB_RTC_GTFS_SNAPSHOT=sortie)
  message('Table préparée : ',sortie,'\n',attribution,'\nElle sera utilisée dans cette session R.',
    '\nPour la réutiliser dans une nouvelle session :\n',
    'Sys.setenv(DB_RTC_GTFS_SNAPSHOT = ',encodeString(sortie,quote='"'),')')
  invisible(sortie)
}
