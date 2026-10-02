# Exécuter depuis ce dossier : Rscript --vanilla check-server.R
library(shiny)
invisible(source("app.R", encoding = "UTF-8"))
testServer(explorer_server, {
  session$setInputs(types = house_types, years = c(1820, 2024), graph = "scatter",
    x = "aire_etages_m2", y = "valeur_fonciere_cad", log_axes = TRUE, bins = 30L)
  stopifnot(nrow(selected()) == 600L, nrow(plot_data()) == 600L,
    grepl("600", output$caption), grepl("366 000", output$summary$html, fixed = TRUE))
  session$setInputs(types = "Jumelé")
  stopifnot(nrow(selected()) == 94L, grepl("94", output$caption),
    grepl('types <- c("Jumelé")', output$code, fixed = TRUE))
  session$setInputs(graph = "histogram", bins = 17L, log_axes = FALSE)
  stopifnot(grepl("bins = 17", output$code, fixed = TRUE), grepl("classes", output$question))
  session$setInputs(graph = "boxplot")
  stopifnot(grepl("geom_boxplot", output$code, fixed = TRUE))
  session$setInputs(types = character())
  stopifnot(nrow(selected()) == 0L, grepl("0 observation", output$caption),
    is.na(house_summary(selected())$value))
})
cat("Serveur Shiny : filtres réactifs, résumés, trois vues, code et sélection vide : OK.\n")
