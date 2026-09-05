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

render_activity_contract <- function() {
  metadata <- activity_contract_metadata()
  title_id <- paste0("activity-contract-", activity_contract_html_escape(metadata$id %||% "details"))
  fields <- list(
    "Objectifs d'apprentissage" = activity_contract_list(metadata$learning_objectives),
    "Prérequis" = activity_contract_list(metadata$prerequisites),
    "Critères de réussite" = activity_contract_list(metadata$success_criteria),
    "Adaptations possibles" = activity_contract_list(metadata$adaptations)
  )

  rows <- paste0(
    "<div><dt>", activity_contract_html_escape(names(fields)), "</dt><dd>",
    unname(fields), "</dd></div>", collapse = ""
  )

  cat(
    '<section class="activity-contract" aria-labelledby="', title_id, '">',
    '<p class="activity-contract-kicker">Fiche de mise en œuvre</p>',
    '<h2 id="', title_id, '">Repères pédagogiques</h2>',
    '<p>Les objectifs et critères ci-dessous permettent d’adapter la séance. La disponibilité des ressources ne constitue pas une validation de leur efficacité en classe.</p>',
    '<dl>', rows, '</dl>',
    '<p class="activity-contract-status">Ressources : ',
    activity_contract_html_escape(activity_contract_status_label(metadata$pedagogical_status)),
    '</p></section>',
    sep = ""
  )
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
  cat('\n```r\n', paste(code, collapse = '\n'), '\n```\n', sep = '')
}

activity_preparation_date <- function(value) {
  date <- as.POSIXct(value, format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
  if (is.na(date)) return(value)
  paste0(format(date, "%d/%m/%Y à %H:%M", tz = "America/Toronto"), " (heure du Québec)")
}
