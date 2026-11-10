# La date affichée doit suivre les données choisies pour l’activité.
verifier_graphique_pompiers <- function() {
  dossier <- tempfile(); dir.create(dossier); on.exit(unlink(dossier, recursive = TRUE), add = TRUE)
  ancien <- Sys.getenv('DB_POMPIERS_SNAPSHOT', unset = NA_character_)
  on.exit(if (is.na(ancien)) Sys.unsetenv('DB_POMPIERS_SNAPSHOT') else Sys.setenv(DB_POMPIERS_SNAPSHOT = ancien), add = TRUE)
  for (derniere in c('2026-11-08', '2024-02-29')) {
    fichier <- file.path(dossier, 'interventions.csv')
    readr::write_csv(data.frame(creation_date_time = paste0(c(substr(derniere, 1, 7), substr(derniere, 1, 7)),
        c('-01 12:00:00', paste0('-', substr(derniere, 9, 10), ' 14:00:00'))),
      incident_type = c('A', 'B'), description_groupe = c('A', 'A'),
      nom_arrond = c('Nord', 'Sud'), nombre_unites = c(1L, 2L)), fichier)
    Sys.setenv(DB_POMPIERS_SNAPSHOT = fichier)
    grDevices::pdf(file.path(dossier, 'graphique.pdf'))
    source('datasets/interventions-pompiers-montreal/activite-longue.R', local = TRUE)
    grDevices::dev.off()
    stopifnot(identical(as.character(derniere_date), derniere),
      grepl('Dernier mois possiblement incomplet', graphique$labels$caption, fixed = TRUE),
      grepl(derniere, graphique$labels$caption, fixed = TRUE))
  }
  message('Pompiers : date de couverture et avertissement du graphique vérifiés.')
}
verifier_graphique_pompiers()
