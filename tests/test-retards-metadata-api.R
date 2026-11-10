# Vérifier les métadonnées documentaires et l'accès décrit par le producteur.
verifier_retards_metadata <- function() {
  source('datasets/retards-transport-collectif/preparation-api.R',local=TRUE)
  archive <- 'datasets/retards-transport-collectif/snapshots/20261110T182250Z/source-api.zip'
  stopifnot(identical(digest::digest(file=archive,algo='sha256'),trimws(readLines(paste0(archive,'.sha256'))[1])))
  dossier <- tempfile();dir.create(dossier);on.exit(unlink(dossier,recursive=TRUE),add=TRUE)
  utils::unzip(archive,exdir=dossier)
  fichier <- file.path(dossier,'package-api.json')
  recu <- jsonlite::read_json(paste0(fichier,'.source.json'))
  stopifnot(identical(digest::digest(file=fichier,algo='sha256'),recu$sha256))
  resume <- preparer_retards_api(fichier)
  stopifnot(resume$n_resources_ckan==1L,resume$n_gtfs_resources==1L,
    resume$n_developer_portal_resources==1L,resume$n_direct_download_resources==0L,
    isTRUE(resume$source_requires_developer_account))
  # Un lien HTML sans indication d'accès n'est pas automatiquement un fichier téléchargé.
  payload <- jsonlite::read_json(fichier)
  payload$result$resources[[1]]$description <- 'Documentation générale.'
  modifie <- file.path(dossier,'sans-information.json')
  jsonlite::write_json(payload,modifie,auto_unbox=TRUE,pretty=TRUE)
  sans_preuve <- preparer_retards_api(modifie)
  stopifnot(sans_preuve$n_direct_download_resources==0L, is.na(sans_preuve$source_requires_developer_account))
  message('Transport : métadonnées documentaires et accès vérifiés, sans données de retard.')
}
verifier_retards_metadata()
