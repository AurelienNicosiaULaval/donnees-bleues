# Les filtres regroupent les étiquettes détaillées sans réécrire les notices.
catalogue_navigation <- function() yaml::read_yaml("data/metadata/navigation.yml")

catalogue_group <- function(values, field) {
  terms <- trimws(unlist(strsplit(paste(values, collapse = ";"), ";", fixed = TRUE)))
  groups <- catalogue_navigation()[[field]]
  names(groups)[vapply(groups, function(group) any(terms %in% unlist(group)), logical(1))]
}

catalogue_level <- function(ids) {
  labels <- c(introduction = "Introduction", intermediaire = "Intermédiaire", avance = "Avancé")
  ids <- trimws(unlist(strsplit(paste(ids, collapse = ";"), ";", fixed = TRUE)))
  stopifnot(length(ids) > 0L, all(ids %in% names(labels)))
  unname(labels[ids])
}

catalogue_duration_minutes <- function(value) {
  # La première plage indique la séance; les prolongements facultatifs sont exclus.
  match <- regmatches(value, regexec("^([0-9]+)(?:[[:space:]]*(?:-|à)[[:space:]]*([0-9]+))?[[:space:]]*(minutes?|heures?)", value, perl = TRUE))[[1]]
  if (!length(match)) stop("Durée non reconnue : ", value, call. = FALSE)
  maximum <- as.numeric(if (nzchar(match[3])) match[3] else match[2])
  maximum * if (grepl("heure", match[4])) 60 else 1
}

catalogue_duration <- function(value) {
  maximum <- unname(vapply(value, catalogue_duration_minutes, numeric(1)))
  ifelse(maximum <= 45, "Jusqu’à 45 minutes",
         ifelse(maximum <= 90, "46 à 90 minutes", "Plus de 90 minutes"))
}

catalogue_filter_definitions <- function(subjects, concepts, levels = NULL, durations = NULL) {
  navigation <- catalogue_navigation()
  subjects <- names(navigation$subjects)[names(navigation$subjects) %in% subjects]
  concepts <- names(navigation$concepts)[names(navigation$concepts) %in% concepts]
  if (!is.null(levels)) levels <- c("Introduction", "Intermédiaire", "Avancé")[c("Introduction", "Intermédiaire", "Avancé") %in% levels]
  if (!is.null(durations)) durations <- c("Jusqu’à 45 minutes", "46 à 90 minutes", "Plus de 90 minutes")[c("Jusqu’à 45 minutes", "46 à 90 minutes", "Plus de 90 minutes") %in% durations]
  filters <- list(
    list(name = "theme", label = "Sujet", values = subjects,
         help = "Domaine auquel les données se rapportent."),
    list(name = "concept", label = "Notion", values = concepts,
         help = "Famille de méthodes ou de tâches abordées."))
  if (!is.null(levels)) filters <- c(filters, list(
    list(name = "level", label = "Niveau", values = levels,
         help = "Niveaux couverts par la ressource.")))
  if (!is.null(durations)) filters <- c(filters, list(
    list(name = "duration", label = "Temps à prévoir", values = durations,
         help = "Durée maximale annoncée, hors prolongements.")))
  filters
}
