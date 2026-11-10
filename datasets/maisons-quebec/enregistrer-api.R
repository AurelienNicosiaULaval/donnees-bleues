# Conserver la table pédagogique vérifiée et sa provenance, sans copier le XML complet.
library(readr)
library(jsonlite)
library(digest)
enregistrer_maisons_api <- function(resultat,recus,dossier) {
  table <- resultat$donnees
  if (nrow(table)!=600L || ncol(table)!=19L || any(grepl('adresse|propriet|cadastre|matricule',names(table),ignore.case=TRUE)))
    stop('La table des maisons contient une structure non autorisée.',call.=FALSE)
  dir.create(dossier,recursive=TRUE,showWarnings=FALSE)
  sortie <- file.path(dossier,'table-activite.csv')
  candidat <- tempfile(tmpdir=dossier);on.exit(unlink(candidat),add=TRUE)
  readr::write_csv(table,candidat,na='NA')
  attendu <- 'e631d863ddc48ef7371a1b9ad5993a0dbccd78c350e5558a9c7396054f886008'
  if (!identical(digest::digest(file=candidat,algo='sha256'),attendu))
    stop('La table reconstruite diffère de la version pédagogique 1.0.0.',call.=FALSE)
  if (file.exists(sortie)) {
    if (!identical(digest::digest(file=candidat,algo='sha256'),digest::digest(file=sortie,algo='sha256')))
      stop('La table existante diffère de cette reconstruction.',call.=FALSE)
  } else if (!file.rename(candidat,sortie)) stop('Impossible de conserver la table.',call.=FALSE)
  jsonlite::write_json(list(sources=recus,xml_sha256=resultat$source_xml_sha256,
    unites_xml=resultat$unites_xml,unites_admissibles=resultat$unites_admissibles,
    lignes=resultat$taille,graine=resultat$graine,version_R=as.character(getRversion()),
    sha256_table=digest::digest(file=sortie,algo='sha256'),
    sha256_preparation=digest::digest(file='datasets/maisons-quebec/preparation-api.R',algo='sha256'),
    limite='Le XML complet contient des champs exclus et demeure local.'),
    file.path(dossier,'preparation.json'),auto_unbox=TRUE,pretty=TRUE)
  Sys.setenv(DB_MAISONS_SNAPSHOT=sortie)
  message('Table préparée : ',sortie,'\nElle sera utilisée dans cette session R.',
    '\nPour la réutiliser dans une nouvelle session :\n',
    'Sys.setenv(DB_MAISONS_SNAPSHOT = ',encodeString(sortie,quote='"'),')')
  invisible(sortie)
}
