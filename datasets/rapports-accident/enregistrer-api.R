# Conserver la table d'activité et les empreintes de la projection et de sa source.
library(readr)
library(jsonlite)
library(digest)
enregistrer_accidents_api <- function(projection,provenance,dossier) {
  table <- preparer_accidents_api(projection)
  dir.create(dossier,recursive=TRUE,showWarnings=FALSE)
  sortie <- file.path(dossier,'table-activite.csv')
  candidat <- tempfile(tmpdir=dossier);on.exit(unlink(candidat),add=TRUE)
  readr::write_csv(table,candidat,na='NA')
  attendu <- '45ddaeff5620e780edb5909a5d2a1efb0e14ab4a3b905d880532205d2ad8cd89'
  if (!identical(digest::digest(file=candidat,algo='sha256'),attendu))
    stop('La table ne correspond pas à la version des activités 2022.',call.=FALSE)
  if (file.exists(sortie)) {
    if (!identical(digest::digest(file=sortie,algo='sha256'),attendu)) stop('Table existante différente.',call.=FALSE)
  } else if (!file.rename(candidat,sortie)) stop('Impossible de conserver la table.',call.=FALSE)
  jsonlite::write_json(list(source=provenance,sha256_projection=digest::digest(file=projection,algo='sha256'),
    sha256_table=attendu,sha256_preparation=digest::digest(file='datasets/rapports-accident/preparation-api.R',algo='sha256'),
    lignes=nrow(table),colonnes=names(table)),file.path(dossier,'preparation.json'),auto_unbox=TRUE,pretty=TRUE)
  Sys.setenv(DB_ACCIDENTS_SNAPSHOT=sortie)
  message('Table préparée : ',sortie,'\nElle sera utilisée dans cette session R.',
    '\nPour la réutiliser dans une nouvelle session :\n',
    'Sys.setenv(DB_ACCIDENTS_SNAPSHOT = ',encodeString(sortie,quote='"'),')')
  invisible(sortie)
}
