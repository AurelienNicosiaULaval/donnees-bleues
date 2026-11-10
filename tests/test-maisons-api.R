# Vérifier la copie pédagogique et refuser un XML ou un index non conformes.
verifier_maisons_api <- function() {
  source('R/utils_ckan.R',local=TRUE)
  source('datasets/maisons-quebec/preparation-api.R',local=TRUE)
  archive <- 'datasets/maisons-quebec/snapshots/20261110T191348Z/source-api.zip'
  stopifnot(identical(digest::digest(file=archive,algo='sha256'),trimws(readLines(paste0(archive,'.sha256'))[1])))
  entrees <- utils::unzip(archive,list=TRUE)$Name
  stopifnot(!any(grepl('[.]xml$',entrees,ignore.case=TRUE)))
  dossier <- tempfile();dir.create(dossier);on.exit(unlink(dossier,recursive=TRUE),add=TRUE)
  utils::unzip(archive,exdir=dossier)
  index <- file.path(dossier,'index','donnees-api.csv')
  ancien <- Sys.getenv('DB_OFFLINE',unset=NA_character_)
  on.exit(if(is.na(ancien)) Sys.unsetenv('DB_OFFLINE') else Sys.setenv(DB_OFFLINE=ancien),add=TRUE)
  Sys.setenv(DB_OFFLINE='true');ckan_datastore_download('c0e65c47-fcc1-40e4-bc2e-7baa74bc164a',index)
  stopifnot(identical(url_maisons_api(index),'https://donneesouvertes.affmunqc.net/role/RL23027_2026.xml'))
  provenance <- jsonlite::read_json(file.path(dossier,'provenance-api.json'))
  table <- file.path(dossier,'maisons-activite.csv')
  stopifnot(identical(digest::digest(file=table,algo='sha256'),provenance$sha256_table),
    provenance$unites_admissibles==99072L,provenance$lignes==600L)
  x <- readr::read_csv(table,show_col_types=FALSE)
  stopifnot(nrow(x)==600L,ncol(x)==19L,!any(grepl('adresse|propriet|cadastre|matricule',names(x),ignore.case=TRUE)))
  faux_xml <- file.path(dossier,'modifie.xml');writeLines('<RL/>',faux_xml)
  stopifnot(inherits(tryCatch(preparer_maisons_api(index,faux_xml),error=identity),'error'))
  donnees <- readr::read_csv(index,col_types=readr::cols(.default=readr::col_character()),show_col_types=FALSE)
  donnees$lien[donnees[['code geographique']]=='23027'] <- 'https://example.org/autre.xml'
  mauvais_index <- file.path(dossier,'index-modifie.csv');readr::write_csv(donnees,mauvais_index)
  stopifnot(inherits(tryCatch(url_maisons_api(mauvais_index),error=identity),'error'))
  message('Maisons : index API, copie pédagogique et refus des sources modifiées vérifiés.')
}
verifier_maisons_api()
