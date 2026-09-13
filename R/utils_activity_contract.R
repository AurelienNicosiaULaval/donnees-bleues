source(if (file.exists("R/utils_editorial.R")) "R/utils_editorial.R" else "../../R/utils_editorial.R")
source(if (file.exists("R/utils_resource_identity.R")) "R/utils_resource_identity.R" else "../../R/utils_resource_identity.R")
`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0L || all(is.na(x))) y else x
}

activity_contract_html_escape <- function(value) {
  value <- as.character(value)
  value[is.na(value)] <- ""
  value <- gsub("&", "&amp;", value, fixed = TRUE)
  value <- gsub("<", "&lt;", value, fixed = TRUE)
  value <- gsub(">", "&gt;", value, fixed = TRUE)
  value <- gsub('"', "&quot;", value, fixed = TRUE)
  gsub("'", "&#39;", value, fixed = TRUE)
}

activity_contract_values <- function(value) {
  value <- unlist(value %||% character(), use.names = FALSE)
  value <- trimws(as.character(value))
  value[!is.na(value) & nzchar(value)]
}

activity_contract_list <- function(value) {
  values <- activity_contract_values(value)
  paste0(
    "<ul>",
    paste0("<li>", activity_contract_html_escape(values), "</li>", collapse = ""),
    "</ul>"
  )
}

activity_contract_status_label <- function(value) {
  switch(
    as.character(value %||% ""),
    pret_a_enseigner = "Fichiers inclus",
    a_consolider = "Acquisition préalable",
    ebauche = "Ébauche",
    "Je ne sais pas."
  )
}

activity_contract_metadata <- function() {
  input <- tryCatch(knitr::current_input(dir = TRUE), error = function(e) NA_character_)
  if (length(input) == 0L || is.na(input) || !nzchar(input)) {
    stop("Impossible d'identifier la page d'activité en cours de rendu.", call. = FALSE)
  }

  input <- normalizePath(input, mustWork = FALSE)
  metadata_path <- file.path(
    dirname(input),
    paste0(tools::file_path_sans_ext(basename(input)), ".yml")
  )
  if (!file.exists(metadata_path)) {
    stop("Métadonnées d'activité introuvables : ", metadata_path, call. = FALSE)
  }
  if (!requireNamespace("yaml", quietly = TRUE)) {
    stop("Le package yaml est requis pour afficher le contrat pédagogique.", call. = FALSE)
  }

  yaml::read_yaml(metadata_path)
}

render_activity_header <- function() {
  metadata <- activity_contract_metadata()
  escape <- activity_contract_html_escape
  cat('<header class="activity-resource-hero resource-detail-header">',
    '<nav class="dataset-breadcrumb" aria-label="Fil d’Ariane"><a href="../../activites.html">Activités</a><span>/</span><a href="fiche.html">',
    escape(metadata$dataset_title), '</a></nav>', resource_identity_html(metadata, 'activite', show_dates = FALSE),
    '<h1>', escape(metadata$title), '</h1>',
    '<p class="resource-intro">', escape(metadata$question), '</p>',
    '<p class="activity-resource-meta">', escape(metadata$duration), ' · ', escape(metadata$level), '</p>',
    '<p class="activity-output"><span>À produire :</span> ', escape(metadata$expected_output), '</p>',
    '<p class="activity-prerequisites"><span>Prérequis :</span> ', escape(editorial_sentences(metadata$prerequisites)), '</p>',
    '</header>', sep = '')
}

render_activity_contract <- function() {
  metadata <- activity_contract_metadata()
  input <- normalizePath(knitr::current_input(dir = TRUE), mustWork = TRUE)
  dataset <- yaml::read_yaml(file.path(dirname(input), 'metadata.yml'))
  source <- paste(readLines(input, warn = FALSE, encoding = 'UTF-8'), collapse = '\n')
  # A task already stated in the instructions is not repeated as an objective
  # or a criterion. Keep distinct criteria and adaptations from the metadata.
  repeated <- function(value) grepl(value, source, fixed = TRUE)
  objectives <- activity_contract_values(metadata$learning_objectives)
  objectives <- objectives[!vapply(objectives, repeated, logical(1))]
  objectives <- objectives[objectives != 'Formuler une limite qui découle de la source et de l’unité observée.']
  criteria <- activity_contract_values(metadata$success_criteria)
  criteria <- criteria[!vapply(criteria, repeated, logical(1))]
  escape <- activity_contract_html_escape
  cat('<section class="activity-contract"><h2>Vérifier le travail</h2>', activity_contract_list(criteria),
      '<details><summary>Objectifs et adaptations</summary>', sep = '')
  if (length(objectives)) cat('<h3>Objectifs</h3>', activity_contract_list(objectives), sep = '')
  cat('<h3>Adaptations</h3>', activity_contract_list(metadata$adaptations), '</details>',
      '<p>Statut documenté : ', escape(metadata$status), '.</p>',
      '<div class="resource-record"><p>Contribution pédagogique : ', escape(dataset$contributor_name %||% 'Non documentée'),
      '. ', escape(editorial_course_label(metadata$courses)), '.</p>', resource_dates_html(metadata, compact = TRUE),
      '</div></section>', sep = '')
}

activity_project_path <- function(path) {
  if (file.exists(path)) return(path)
  alternative <- file.path('../..', path)
  if (file.exists(alternative)) return(alternative)
  stop('Ressource d’activité absente : ', path, call. = FALSE)
}

render_activity_resources <- function() {
  metadata <- activity_contract_metadata()
  receipt_path <- activity_project_path(paste0(metadata$classroom_archive, '.json'))
  receipt <- jsonlite::read_json(receipt_path)
  label <- switch(receipt$mode,
    frozen = 'Télécharger la trousse avec les données',
    documentation = 'Télécharger la trousse documentaire',
    source_required = 'Télécharger les scripts, sans les données')
  archive_url <- paste0('../../', metadata$classroom_archive)
  cat('<div class="activity-download"><p><a class="btn btn-primary" href="',
    activity_contract_html_escape(archive_url), '" download>', label, '</a></p>',
    '<p>', format(round(receipt$archive_bytes / 1024), big.mark = ' '), ' Ko. Préparation : ',
    activity_contract_html_escape(activity_preparation_date(receipt$prepared_at_utc)), '.</p>',
    '<p>', activity_contract_html_escape(switch(receipt$mode, frozen = 'Les fichiers de données sont inclus dans la trousse.', documentation = 'Cette trousse contient la documentation publique utilisée par le script.', source_required = 'Les données doivent être obtenues auprès de la source avant la séance.')), '</p>',
    '<p><a href="', activity_contract_html_escape(receipt$license_url), '">Conditions de la source</a> · ',
    '<a href="', activity_contract_html_escape(paste0(archive_url, '.json')), '">Provenance et empreinte du ZIP</a></p>', sep = '')
  if (length(receipt$tables)) {
    cat('<details><summary>Fichiers inclus</summary><ul>')
    for (table in receipt$tables) {
      cat('<li><code>', activity_contract_html_escape(basename(table$path)), '</code> : ',
          format(table$rows, big.mark = ' '), ' lignes, ', length(table$columns), ' colonnes.</li>', sep = '')
    }
    cat('</ul></details>')
  }
  if (metadata$dataset_id == 'meteo-quebec') {
    cat('<p>Données gratuites d’Environnement et Changement climatique Canada. Leur utilisation vaut acceptation des conditions liées ci-dessus; conserver ces conditions lors d’une redistribution.</p>')
  }
  cat('</div>\n')
}

render_activity_code <- function() {
  metadata <- activity_contract_metadata()
  code <- readLines(activity_project_path(metadata$script_file), warn = FALSE, encoding = 'UTF-8')
  cat('\n<details class="activity-code-panel"><summary>Afficher le script R</summary>\n\n```r\n',
      paste(code, collapse = '\n'), '\n```\n\n</details>\n', sep = '')
}

activity_preparation_date <- function(value) {
  date <- as.POSIXct(value, format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
  if (is.na(date)) return(value)
  paste0(format(date, "%d/%m/%Y à %H:%M", tz = "America/Toronto"), " (heure du Québec)")
}
