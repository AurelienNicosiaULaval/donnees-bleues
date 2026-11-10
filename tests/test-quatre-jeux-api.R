# Vérifier les réponses archivées et des propriétés pertinentes pour les activités.
verifier_copie <- function(id, date, resource_id, preparer, controles) {
  source('R/utils_ckan.R', local = TRUE)
  source(file.path('datasets', id, 'preparation-api.R'), local = TRUE)
  archive <- file.path('datasets', id, 'snapshots', date, 'source-api.zip')
  stopifnot(identical(digest::digest(file = archive, algo = 'sha256'),
    trimws(readLines(paste0(archive, '.sha256'))[1])))
  dossier <- tempfile(); dir.create(dossier)
  on.exit(unlink(dossier, recursive = TRUE), add = TRUE)
  utils::unzip(archive, exdir = dossier)
  fichier <- file.path(dossier, 'donnees-api.csv')
  ancien <- Sys.getenv('DB_OFFLINE', unset = NA_character_)
  on.exit(if (is.na(ancien)) Sys.unsetenv('DB_OFFLINE') else Sys.setenv(DB_OFFLINE = ancien), add = TRUE)
  Sys.setenv(DB_OFFLINE = 'true')
  ckan_datastore_download(resource_id, fichier)
  brut <- readr::read_csv(fichier, show_col_types = FALSE)
  recu <- jsonlite::read_json(paste0(fichier, '.source.json'))
  autorises <- c('_id', unlist(recu$details$columns))
  for (page in recu$details$pages) {
    reponse <- jsonlite::read_json(file.path(dossier, page$file))
    stopifnot(all(vapply(reponse$result$records,
      function(ligne) all(names(ligne) %in% autorises), logical(1))))
  }
  controles(get(preparer)(fichier), brut)
}
verifier_copie('condamnations-alimentaires-quebec', '20261110T153456Z',
  '40105615-3abf-414b-bcba-182e8f2c5eb2', 'preparer_condamnations_api',
  function(x, brut) stopifnot(nrow(x) == 2943L, !anyNA(x$amende_num),
    !any(grepl('Nom_exploitant|Raison_sociale|Adresse', names(brut)))))
verifier_copie('prelevements-eau-autorises', '20261110T153456Z',
  '5c090292-a681-4413-9399-f17bcdf62753', 'preparer_prelevements_api',
  function(x, brut) stopifnot(nrow(x) == 1777L,
    all(x$volume_autorise_m3_j == x$volume_autorise_l_j / 1000, na.rm = TRUE)))
verifier_copie('defavorisation-ecoles-primaires', '20261110T153456Z',
  '6c5d4a5d-ba3b-40a6-b570-916f43ab622c', 'preparer_defavorisation_api',
  function(x, brut) stopifnot(nrow(x) == 1963L, sum(x$Diffusion == 'NON') == 68L,
    all(is.na(x$IMSE[x$Diffusion == 'NON'])), all(is.na(x$SFR[x$Diffusion == 'NON']))))
verifier_copie('arbres-publics-montreal', '20261110T153551Z',
  '64e28fe6-ef37-437a-972d-d1d3f1f7d891', 'preparer_arbres_api',
  function(x, brut) stopifnot(nrow(x) == 336607L,
    identical(names(x), c('arrondissement', 'essence_fr', 'dhp'))))
verifier_copie('budgets-municipaux-quebec', '20261110T154129Z',
  '15192f34-a635-47f5-aaf9-eb1621d65b2e', 'preparer_budgets_api',
  function(x, brut) stopifnot(nrow(x) == 1105L, !anyDuplicated(x$code_geographique),
    all(nchar(x$code_geographique) == 5L)))
message('Cinq copies API vérifiées, y compris les colonnes non nominatives et les suppressions.')
