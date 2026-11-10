# Parcourir les demandes non-Information par clé et effectuer un échantillonnage réservoir.
library(jsonlite)
library(httr2)
library(readr)
library(digest)
source('R/utils_downloads.R')

acquerir_requetes_api <- function(dossier, taille = 100000L, graine = 311L, taille_page = 10000L, fetch = NULL) {
  resource <- '2cfa0e06-9be4-49a6-b7f1-ee9f2363a872'
  endpoint <- 'https://www.donneesquebec.ca/recherche/api/3/action/datastore_search_sql'
  champs <- c('NATURE', 'ACTI_NOM', 'ARRONDISSEMENT', 'DDS_DATE_CREATION', 'DATE_DERNIER_STATUT')
  if (dir.exists(dossier)) stop('Choisir un dossier de collecte nouveau.', call. = FALSE)
  if (length(taille) != 1L || is.na(taille) || taille < 1L || taille != as.integer(taille) ||
      length(taille_page) != 1L || is.na(taille_page) || taille_page < 1L || taille_page != as.integer(taille_page))
    stop('Taille d’échantillon ou de page invalide.', call. = FALSE)
  if (is.null(fetch)) fetch <- function(url, path) download_source(url, path)
  dir.create(file.path(dossier, 'pages'), recursive = TRUE)
  ancien_kind <- RNGkind(); avait_graine <- exists('.Random.seed', envir = .GlobalEnv, inherits = FALSE)
  if (avait_graine) ancienne_graine <- get('.Random.seed', envir = .GlobalEnv)
  on.exit({do.call(RNGkind, as.list(ancien_kind)); if (avait_graine) assign('.Random.seed', ancienne_graine, envir = .GlobalEnv)
    else if (exists('.Random.seed', envir = .GlobalEnv, inherits = FALSE)) rm('.Random.seed', envir = .GlobalEnv)}, add = TRUE)
  RNGkind('Mersenne-Twister', 'Inversion', 'Rejection'); set.seed(graine)
  lancer <- function(sql, nom) {
    # Le réseau et les éventuelles nouvelles tentatives ne doivent pas modifier le tirage.
    graine_tirage <- get('.Random.seed', envir = .GlobalEnv)
    on.exit(assign('.Random.seed', graine_tirage, envir = .GlobalEnv), add = TRUE)
    req <- httr2::req_url_query(httr2::request(endpoint), sql = sql)
    path <- file.path(dossier, 'pages', paste0(nom, '.json'))
    fetch(req$url, path)
    x <- jsonlite::read_json(path, simplifyVector = TRUE)
    if (!isTRUE(x$success)) stop('Échec de la requête SQL : ', nom, call. = FALSE)
    x$result$records
  }
  max_id <- lancer(sprintf('SELECT MAX("_id") AS maximum FROM "%s"', resource), 'borne')$maximum[[1]]
  if (is.null(max_id) || is.na(max_id) || max_id <= 0) stop('Borne API invalide.', call. = FALSE)
  filtre <- sprintf("FROM \"%s\" WHERE \"_id\" <= %.0f AND (\"NATURE\" != 'Information' OR \"NATURE\" IS NULL)", resource, max_id)
  compter <- function(nom) lancer(paste('SELECT COUNT(*) AS nombre', filtre), nom)$nombre[[1]]
  total_initial <- compter('compte-debut')
  if (is.na(total_initial) || total_initial < taille) stop('Nombre de demandes insuffisant.', call. = FALSE)
  colonnes_sql <- paste(sprintf('"%s"', c('_id', champs)), collapse = ', ')
  stockage <- as.data.frame(setNames(replicate(length(champs), rep(NA_character_, taille), simplify = FALSE), champs), stringsAsFactors = FALSE)
  dernier <- 0; nombre <- 0L; numero <- 0L; date_max_population <- NA_character_
  repeat {
    sql <- sprintf('SELECT %s %s AND "_id" > %.0f ORDER BY "_id" ASC LIMIT %d', colonnes_sql, filtre, dernier, taille_page)
    numero <- numero + 1L
    lots <- lancer(sql, sprintf('page-%05d', numero))
    if (is.null(lots) || !length(lots) || (is.data.frame(lots) && !nrow(lots))) break
    if (!is.data.frame(lots)) stop('Page de demandes 311 invalide.', call. = FALSE)
    if (!identical(names(lots), c('_id', champs)) || anyNA(lots$`_id`) ||
        is.unsorted(lots$`_id`, strictly = TRUE) || lots$`_id`[[1]] <= dernier ||
        any(lots$`_id` > max_id) || nrow(lots) > taille_page)
      stop('Schéma ou pagination 311 incohérents.', call. = FALSE)
    dates <- as.character(lots$DDS_DATE_CREATION)
    dates <- dates[!is.na(dates) & nzchar(dates)]
    if (length(dates)) date_max_population <- max(c(date_max_population, dates), na.rm = TRUE)
    positions <- integer(nrow(lots))
    for (i in seq_len(nrow(lots))) {
      position_source <- nombre + i
      positions[[i]] <- if (position_source <= taille) position_source else sample.int(position_source, 1L)
    }
    retenues <- which(positions <= taille)
    retenues <- retenues[!duplicated(positions[retenues], fromLast = TRUE)]
    for (champ in champs) stockage[positions[retenues], champ] <- as.character(lots[[champ]][retenues])
    nombre <- nombre + nrow(lots); dernier <- tail(lots$`_id`, 1)
    message('Demandes non-Information parcourues : ', nombre, ' / ', total_initial)
    if (nrow(lots) < taille_page) break
  }
  total_final <- compter('compte-fin')
  if (nombre != total_initial || total_final != total_initial)
    stop('La ressource a changé durant la collecte; aucun échantillon finalisé.', call. = FALSE)
  echantillon <- file.path(dossier, 'echantillon-api.csv')
  readr::write_csv(stockage, echantillon, na = 'NA')
  pages <- sort(list.files(file.path(dossier, 'pages'), pattern = '[.]json$', full.names = TRUE))
  pages <- pages[!grepl('[.]source[.]json$', pages)]
  recu <- list(source_url = endpoint, resource_id = resource, acquisition_utc = format(Sys.time(), '%Y-%m-%dT%H:%M:%SZ', tz = 'UTC'),
    borne_id_max = max_id, population_non_information = nombre, taille_echantillon = taille,
    date_creation_max_population = date_max_population,
    methode = 'Échantillonnage réservoir uniforme sans remise, parcours par identifiant API croissant',
    graine = graine, rng = RNGkind(), version_R = as.character(getRversion()),
    sha256_acquisition = digest::digest(file = 'datasets/requetes-311/acquerir-api.R', algo = 'sha256'),
    champs_diffuses = champs, sha256_echantillon = digest::digest(file = echantillon, algo = 'sha256'),
    pages = lapply(pages, function(p) list(fichier = basename(p), sha256 = digest::digest(file = p, algo = 'sha256'))),
    limite = 'La collecte paginée ne constitue pas une transaction atomique. Un effectif identique ne détecte pas toutes les modifications simultanées.')
  jsonlite::write_json(recu, file.path(dossier, 'provenance-api.json'), auto_unbox = TRUE, pretty = TRUE)
  invisible(echantillon)
}
