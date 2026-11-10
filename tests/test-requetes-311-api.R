# Contrôler l'échantillon distribué et l'algorithme de réservoir sur des données factices.
verifier_requetes_api <- function() {
  ancien_kind <- RNGkind(); avait_graine <- exists('.Random.seed', envir=.GlobalEnv, inherits=FALSE)
  if (avait_graine) ancienne_graine <- get('.Random.seed', envir=.GlobalEnv)
  on.exit({do.call(RNGkind, as.list(ancien_kind)); if (avait_graine) assign('.Random.seed',ancienne_graine,envir=.GlobalEnv)
    else if (exists('.Random.seed',envir=.GlobalEnv,inherits=FALSE)) rm('.Random.seed',envir=.GlobalEnv)}, add=TRUE)
  source('datasets/requetes-311/acquerir-api.R', local = TRUE)
  source('datasets/requetes-311/preparation-api.R', local = TRUE)
  archive <- 'datasets/requetes-311/snapshots/20261110T181619Z/source-api.zip'
  stopifnot(identical(digest::digest(file = archive, algo = 'sha256'),
    trimws(readLines(paste0(archive, '.sha256'))[1])))
  noms <- utils::unzip(archive, list = TRUE)$Name
  stopifnot(setequal(noms, c('echantillon-api.csv', 'provenance-api.json')))
  stage <- tempfile(); dir.create(stage); on.exit(unlink(stage, recursive = TRUE), add = TRUE)
  utils::unzip(archive, exdir = stage)
  chemin <- file.path(stage, 'echantillon-api.csv')
  provenance <- jsonlite::read_json(file.path(stage, 'provenance-api.json'))
  stopifnot(identical(digest::digest(file = chemin, algo = 'sha256'), provenance$sha256_echantillon),
    provenance$population_non_information == 1239599, provenance$taille_echantillon == 100000,
    provenance$date_creation_max_population == '2025-07-20T21:56:25')
  x <- preparer_requetes_api(chemin)
  stopifnot(nrow(x) == 100000L, sum(x$nature == 'Requete') == 96662L,
    identical(names(x), c('nature','activite','arrondissement','date_creation','delai_statut_jours')))

  donnees <- data.frame(`_id` = seq_len(23), NATURE = rep('Requete',23),
    ACTI_NOM = paste0('activité ',seq_len(23)), ARRONDISSEMENT = rep('A',23),
    DDS_DATE_CREATION = rep('2025-01-01T00:00:00',23), DATE_DERNIER_STATUT = rep('2025-01-02T00:00:00',23),
    check.names = FALSE, stringsAsFactors = FALSE)
  compte <- 0L
  fetch <- function(url, path) {
    # Simuler une requête qui consomme de l'aléa pour tester l'isolation du tirage.
    runif(1)
    sql <- utils::URLdecode(sub('^.*sql=', '', url))
    if (grepl('MAX\\(', sql)) lignes <- data.frame(maximum = 23L)
    else if (grepl('COUNT\\(', sql)) {compte <<- compte + 1L; lignes <- data.frame(nombre = 23L)}
    else {
      dernier <- as.integer(sub('.*"_id" > ([0-9]+).*', '\\1', sql))
      lignes <- head(donnees[donnees$`_id` > dernier,,drop=FALSE], 3L)
    }
    jsonlite::write_json(list(success = TRUE, result = list(records = lignes)), path, auto_unbox = TRUE)
  }
  set.seed(99); ancienne_graine <- .Random.seed
  fichier <- acquerir_requetes_api(file.path(stage,'collecte'), taille=5L, graine=311L, taille_page=3L, fetch=fetch)
  stopifnot(identical(.Random.seed, ancienne_graine), compte == 2L)
  RNGkind('Mersenne-Twister','Inversion','Rejection'); set.seed(311L)
  positions <- seq_len(5L)
  for (i in 6:23) {j <- sample.int(i,1); if (j <= 5) positions[[j]] <- i}
  echantillon <- readr::read_csv(fichier, col_types=readr::cols(.default=readr::col_character()),show_col_types=FALSE)
  stopifnot(identical(echantillon$ACTI_NOM, donnees$ACTI_NOM[positions]))
  comptes_modifies <- 0L
  fetch_change <- function(url, path) {
    sql <- utils::URLdecode(sub('^.*sql=', '', url))
    if (grepl('COUNT\\(', sql)) {
      comptes_modifies <<- comptes_modifies + 1L
      if (comptes_modifies == 2L) {
        jsonlite::write_json(list(success=TRUE, result=list(records=data.frame(nombre=24L))), path, auto_unbox=TRUE)
        return(invisible(NULL))
      }
    }
    fetch(url, path)
  }
  invalide <- file.path(stage, 'population-modifiee')
  erreur <- tryCatch(acquerir_requetes_api(invalide, taille=5L, graine=311L, taille_page=3L,
    fetch=fetch_change), error=identity)
  stopifnot(inherits(erreur, 'error'), !file.exists(file.path(invalide, 'echantillon-api.csv')))
  message('311 : archive, couverture et tirage réservoir vérifiés.')
}
verifier_requetes_api()
