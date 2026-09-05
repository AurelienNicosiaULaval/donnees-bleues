# Build and validate self-contained teaching kits from explicit publication policies.
classroom_script_paths <- function(id) {
  file.path('datasets', id, c('activite-courte.R', 'activite-longue.R'))
}

classroom_policy <- function(metadata) {
  policy <- metadata$publication$classroom
  if (is.null(policy) || !policy$mode %in% c('frozen', 'documentation', 'source_required') ||
      is.null(policy$reason) || !nzchar(policy$reason)) {
    stop('Politique de trousse absente : ', metadata$id, call. = FALSE)
  }
  if (policy$mode == 'source_required' && length(policy$files)) {
    stop('Une source non redistribuable ne peut fournir des CSV de classe.', call. = FALSE)
  }
  paths <- vapply(policy$files, function(file) file$path, character(1))
  if (anyDuplicated(paths)) stop('Fichier de classe déclaré deux fois.', call. = FALSE)
  for (file in policy$files) {
    prefix <- paste0('data/processed/', metadata$id, '/')
    if (!startsWith(file$path, prefix) || grepl('..', file$path, fixed = TRUE) ||
        !grepl('[.]csv$', file$path) || !length(file$columns) || anyDuplicated(file$columns)) {
      stop('Chemin ou colonnes de classe invalides : ', metadata$id, call. = FALSE)
    }
  }
  policy
}

classroom_packages <- function(paths) {
  code <- paste(unlist(lapply(paths, readLines, warn = FALSE)), collapse = '\n')
  libraries <- regmatches(code, gregexpr('library\\([A-Za-z][A-Za-z0-9.]*\\)', code))[[1]]
  libraries <- sub('library\\((.*)\\)', '\\1', libraries)
  namespaces <- regmatches(code, gregexpr('[A-Za-z][A-Za-z0-9.]*::', code))[[1]]
  sort(setdiff(unique(c(libraries, sub('::$', '', namespaces))), c('base', 'utils', 'tools', 'stats', 'grDevices')))
}

classroom_sha <- function(path) digest::digest(file = path, algo = 'sha256')

build_classroom_kit <- function(metadata, output_dir = 'assets/classroom') {
  policy <- classroom_policy(metadata)
  id <- metadata$id
  scripts <- classroom_script_paths(id)
  if (!all(file.exists(scripts))) stop('Scripts de classe absents : ', id, call. = FALSE)
  references <- unique(unlist(lapply(scripts, function(path) {
    code <- paste(readLines(path, warn = FALSE), collapse = '\n')
    refs <- regmatches(code, gregexpr('"data/processed/[^"\n]+[.]csv"', code))[[1]]
    gsub('"', '', refs, fixed = TRUE)
  })))
  allowed <- vapply(policy$files, function(file) file$path, character(1))
  if (policy$mode != 'source_required' && !setequal(references, allowed)) {
    stop('Les entrées du script et la politique diffèrent : ', id, call. = FALSE)
  }
  stage <- tempfile('classroom-')
  dir.create(stage)
  on.exit(unlink(stage, recursive = TRUE), add = TRUE)
  copy <- function(path) {
    dest <- file.path(stage, path)
    dir.create(dirname(dest), recursive = TRUE, showWarnings = FALSE)
    if (!file.copy(path, dest, overwrite = TRUE)) stop('Copie impossible : ', path)
  }
  for (path in c(scripts, 'LICENSE', 'LICENCE-CONTENUS.md')) copy(path)
  source_paths <- scripts
  if (policy$mode == 'source_required') {
    source_paths <- c(source_paths, file.path('datasets', id, 'preparation.R'),
                      'R/utils_downloads.R', 'R/utils_data_checks.R')
    for (path in setdiff(source_paths, scripts)) copy(path)
    writeLines(c('# Connexion requise. Consulter les conditions de la source avant utilisation.',
      paste0('# ', metadata$publication$license_url),
      paste0('source("datasets/', id, '/preparation.R")')),
      file.path(stage, 'preparer-donnees.R'))
  }
  tables <- list()
  for (file in policy$files) {
    # Character import preserves identifiers, dates and published numeric strings exactly.
    full <- readr::read_csv(file$path, col_types = readr::cols(.default = readr::col_character()), show_col_types = FALSE)
    cols <- unlist(file$columns, use.names = FALSE)
    if (!all(cols %in% names(full))) stop('Colonne de classe manquante : ', file$path)
    data <- full[, cols, drop = FALSE]
    if (id == 'defavorisation-ecoles-primaires') {
      private <- !is.na(data$Diffusion) & data$Diffusion != 'OUI'
      if (any(!is.na(data$IMSE[private])) || any(!is.na(data$SFR[private]))) stop('Indices protégés détectés.')
    }
    if (id == 'ulaval-programmes-cours' && 'source_found' %in% names(data) &&
        any(toupper(data$source_found) != 'FALSE')) stop('La trousse ULaval doit rester une documentation sans données privées.')
    destination <- file.path(stage, file$path)
    dir.create(dirname(destination), recursive = TRUE, showWarnings = FALSE)
    readr::write_csv(data, destination, na = 'NA')
    tables[[length(tables) + 1L]] <- list(path = file$path, rows = nrow(data), columns = cols,
      sha256 = classroom_sha(destination), prepared_table_sha256 = classroom_sha(file$path))
  }
  packages <- classroom_packages(source_paths)
  package_code <- paste(sprintf('"%s"', packages), collapse = ', ')
  writeLines(c('# À exécuter une fois avec Internet avant la séance.',
    paste0('packages <- c(', package_code, ')'),
    'absents <- setdiff(packages, rownames(installed.packages()))',
    'if (length(absents)) install.packages(absents, repos = "https://cloud.r-project.org")',
    'stopifnot(all(vapply(packages, requireNamespace, logical(1), quietly = TRUE)))'),
    file.path(stage, 'installer-packages.R'))
  writeLines(c('Version: 1.0', '', 'RestoreWorkspace: No', 'SaveWorkspace: No',
    'AlwaysSaveHistory: No', 'Encoding: UTF-8', 'UseNativePipeOperator: Yes'),
    file.path(stage, 'Donnees-bleues.Rproj'))
  prep_manifest <- jsonlite::read_json(file.path('data/processed', id, 'manifest.json'))
  sources <- lapply(prep_manifest$sources, function(source) source[c('source_url', 'acquisition_kind', 'acquired_at_utc', 'sha256')])
  manifest <- list(dataset_id = id, title = metadata$title, mode = policy$mode,
    prepared_at_utc = prep_manifest$prepared_at_utc, source_name = metadata$source_name,
    source_url = metadata$source_url, license_url = metadata$publication$license_url,
    original_licenses = list(code = 'MIT', content = 'CC-BY-4.0',
      notices = c('LICENSE', 'LICENCE-CONTENUS.md')),
    selection = policy$reason, r_version_tested = '4.5.0',
    packages_tested = setNames(lapply(packages, function(p) as.character(utils::packageVersion(p))), packages),
    sources = sources, tables = tables)
  jsonlite::write_json(manifest, file.path(stage, 'provenance.json'), auto_unbox = TRUE, pretty = TRUE)
  availability <- switch(policy$mode,
    frozen = 'Les CSV préparés sont inclus. Le script fonctionne hors ligne après installation des packages.',
    documentation = 'Seule la documentation publique est incluse. Le script examine ce protocole ou cet index; il ne valide pas des données privées, une géodatabase ou des retards observés.',
    source_required = 'Les données ISQ ne sont pas incluses. Après lecture des conditions de la source, ouvrir preparer-donnees.R et cliquer Source avec Internet avant la séance. Les CSV seront créés sur votre ordinateur. Ne pas redistribuer ces CSV sans autorisation applicable.')
  lines <- c(paste0('# ', metadata$title), '', availability, '',
    '1. Extraire tout le ZIP dans un dossier.',
    '2. Double-cliquer sur Donnees-bleues.Rproj pour ouvrir RStudio.',
    '3. Avant la séance, ouvrir installer-packages.R et cliquer Source avec Internet.',
    if (policy$mode == 'source_required') '4. Ouvrir preparer-donnees.R et cliquer Source avec Internet.' else '4. Conserver les sous-dossiers de données à leur place.',
    paste0('5. Ouvrir datasets/', id, '/activite-courte.R ou activite-longue.R, puis cliquer Source.'),
    '6. Lire les tableaux dans Console et les graphiques dans Plots. Les consignes propres à chaque activité sont sur le site.', '',
    paste0('Activités : https://aureliennicosiaulaval.github.io/donnees-bleues/datasets/', id, '/fiche.html'), '',
    '## Source et réutilisation', '', paste0('Producteur : ', metadata$source_name),
    paste0('Source : ', metadata$source_url), paste0('Conditions : ', metadata$publication$license_url),
    paste0('Préparation : ', prep_manifest$prepared_at_utc, ' (UTC). Les dates de chaque acquisition figurent dans provenance.json.'),
    'Transformation : préparation par Données bleues, puis sélection des colonnes déclarées. Les observations et résumés reflètent cet instantané; ils ne sont pas actualisés par les scripts d’activité.',
    'Lors d’une réutilisation, conserver l’attribution au producteur, le lien vers la source, les conditions et la date de préparation. Mentionner vos modifications.',
    if (id == 'meteo-quebec') 'Données climatiques : Environnement et Changement climatique Canada. Données gratuites; consulter les conditions ECCC ci-dessus. Leur utilisation vaut acceptation de ces conditions. Transmettre ces conditions à toute personne recevant les données.',
    if (id == 'transport-collectif-gtfs') paste0('Données ouvertes du Réseau de transport de la Capitale (RTC). Instantané préparé le ', prep_manifest$prepared_at_utc, '. Les dates des téléchargements figurent dans provenance.json.'),
    if (id == 'qualite-air-horaire') 'RSQAQ : heures publiées en HNE (UTC-5 fixe), à la fin de l’intervalle. Les résumés portent sur le jour HNE du début de cet intervalle. Seuls les jours de 2025 sont retenus; la fin du fichier annuel peut donner une couverture partielle du dernier jour. Les PM2,5-T640 sont en µg/m³.',
    '', 'Le code original de Données bleues est sous licence MIT (voir LICENSE). Les textes et activités originales sont sous CC BY 4.0 (voir LICENCE-CONTENUS.md). Les données et autres contenus de tiers conservent les conditions de leurs producteurs indiquées ci-dessus.', '',
    '## Vérification', '', 'provenance.json décrit les tables, colonnes, versions testées et sources. SHA256SUMS donne l’empreinte des fichiers contenus dans cette trousse.')
  writeLines(lines, file.path(stage, 'LISEZ-MOI.md'), useBytes = TRUE)
  files <- sort(list.files(stage, recursive = TRUE, all.files = TRUE, full.names = FALSE))
  checksums <- vapply(file.path(stage, files), classroom_sha, character(1))
  writeLines(paste(checksums, files, sep = '  '), file.path(stage, 'SHA256SUMS'))
  files <- sort(c(files, 'SHA256SUMS'))
  # Fixed file dates and sorted entries make repeated builds of the same inputs identical.
  Sys.setFileTime(file.path(stage, files), as.POSIXct('2000-01-01', tz = 'UTC'))
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  archive <- file.path(normalizePath(output_dir), paste0(id, '.zip'))
  if (file.exists(archive)) unlink(archive)
  zip::zip(archive, files = files, root = stage, include_directories = FALSE, mode = "mirror")
  receipt <- c(manifest[c('dataset_id', 'title', 'mode', 'prepared_at_utc', 'source_name', 'source_url', 'license_url', 'original_licenses', 'selection', 'tables')],
    list(archive_sha256 = classroom_sha(archive), archive_bytes = unname(file.info(archive)$size)))
  jsonlite::write_json(receipt, paste0(archive, '.json'), auto_unbox = TRUE, pretty = TRUE)
  invisible(receipt)
}

read_classroom_table <- function(archive, path) {
  # Only use a declared public CSV from a verified classroom archive.
  entries <- utils::unzip(archive, list = TRUE)$Name
  if (!path %in% entries || !grepl('^data/processed/[^/]+/[^/]+[.]csv$', path)) stop('Table non fournie dans la trousse.')
  destination <- tempfile('classroom-table-')
  dir.create(destination)
  on.exit(unlink(destination, recursive = TRUE), add = TRUE)
  utils::unzip(archive, files = path, exdir = destination)
  readr::read_csv(file.path(destination, path), show_col_types = FALSE)
}
