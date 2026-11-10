# Refaire le traitement original dans un dossier temporaire isolé.
library(digest)
preparer_arbres_forestiers_api <- function(archive, destination) {
  attendu <- '45e66eeb95ea7f3e47aa0840a8a263c1cc2862ccf0b33fd5e007e353ca48174d'
  if (!file.exists(archive) || !identical(digest::digest(file = archive, algo = 'sha256'), attendu))
    stop('Le fichier PET5 diffère de la version source de 2026-06-25.', call. = FALSE)
  reference <- normalizePath('datasets/arbres-quebec/pipeline-reference', mustWork = TRUE)
  dictionnaire <- file.path(reference, 'data_raw/PET5/DICTIONNAIRE_PLACETTE.xlsx')
  if (!identical(digest::digest(file = dictionnaire, algo = 'sha256'), '80030759196a9339cce427aa8756d4429e299c8b801dec0618a19d6eeae6cdc3'))
    stop('Le dictionnaire de référence a changé.', call. = FALSE)
  travail <- tempfile('arbres-pet5-'); dir.create(travail)
  on.exit(unlink(travail, recursive = TRUE), add = TRUE)
  for (d in c('R', 'scripts', 'references', 'data_raw/PET5')) dir.create(file.path(travail, d), recursive = TRUE, showWarnings = FALSE)
  fichiers <- c('R/helpers_io.txt', 'R/helpers_validation.txt', 'scripts/02_clean_botanical_data.txt',
    'references/species_taxonomy_crosswalk.csv', 'references/species_code_exclusions.csv',
    'data_raw/PET5/DICTIONNAIRE_PLACETTE.xlsx', 'data_dictionary.csv')
  for (f in fichiers) {
    cible <- sub('[.]txt$', '.R', f)
    if (!file.copy(file.path(reference, f), file.path(travail, cible))) stop('Copie du traitement impossible.', call. = FALSE)
  }
  if (!file.copy(archive, file.path(travail, 'data_raw/PET5/PET5_GPKG.zip')))
    stop('Copie temporaire PET5 impossible.', call. = FALSE)
  ancien <- getwd(); on.exit(setwd(ancien), add = TRUE); setwd(travail)
  journal <- file.path(travail, 'recalcul.log')
  statut <- system2(file.path(R.home('bin'), 'Rscript'), c('--vanilla', 'scripts/02_clean_botanical_data.R'),
                    env = c('OVERWRITE_CLEAN=true', 'ARBRES_QC_SOURCE=PET5'), stdout = journal, stderr = journal)
  if (statut != 0L) stop('Échec du recalcul PET5 : ', paste(tail(readLines(journal, warn = FALSE), 12), collapse = '\n'), call. = FALSE)
  sortie_temp <- file.path(travail, 'data_clean/arbres_quebec_small.csv')
  if (!file.exists(sortie_temp) || !identical(digest::digest(file = sortie_temp, algo = 'sha256'),
      '1af11ff0fc824f35286987928f0423441540ece1badb674f347ab05db07d4ccf'))
    stop('Le tirage recalculé diffère de la version pédagogique.', call. = FALSE)
  setwd(ancien)
  dir.create(destination, recursive = TRUE, showWarnings = FALSE)
  sortie <- file.path(destination, 'arbres-activite.csv')
  if (file.exists(sortie) && !identical(digest::digest(file = sortie, algo = 'sha256'), digest::digest(file = sortie_temp, algo = 'sha256')))
    stop('La table existante diffère du recalcul.', call. = FALSE)
  if (!file.exists(sortie) && !file.copy(sortie_temp, sortie)) stop('Copie de la table impossible.', call. = FALSE)
  jsonlite::write_json(list(sha256_pet5 = attendu, sha256_dictionnaire = digest::digest(file = dictionnaire, algo = 'sha256'),
    sha256_table = digest::digest(file = sortie, algo = 'sha256'), lignes = 200L,
    prepare_utc = format(Sys.time(), '%Y-%m-%dT%H:%M:%SZ', tz = 'UTC')),
    file.path(destination, 'preparation.json'), pretty = TRUE, auto_unbox = TRUE)
  Sys.setenv(DB_ARBRES_FOREST_SNAPSHOT = sortie)
  message('Table forestière reconstruite : ', sortie, '\nElle sera utilisée dans cette session R.')
  invisible(sortie)
}
