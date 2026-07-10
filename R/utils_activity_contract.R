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
    pret_a_enseigner = "Prête à enseigner",
    a_consolider = "À préparer",
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
    "Préparation enseignante" = activity_contract_list(metadata$teacher_preparation),
    "Production attendue" = activity_contract_list(metadata$expected_output),
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
    '<h2 id="', title_id, '">Contrat pédagogique</h2>',
    '<p>Le statut pédagogique décrit le degré de préparation de l’activité. Il ne remplace pas la vérification de la source de données.</p>',
    '<dl>', rows, '</dl>',
    '<p class="activity-contract-status"><strong>Statut pédagogique :</strong> ',
    activity_contract_html_escape(activity_contract_status_label(metadata$pedagogical_status)),
    '</p></section>',
    sep = ""
  )
}
