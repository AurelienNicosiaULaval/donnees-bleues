# Lancer depuis ce dossier avec shiny::runApp().
library(shiny)
source("R/bootstrap.R", local = TRUE)
houses <- read_bootstrap_houses("data/maisons-quebec.csv")

export_bootstrap_code <- function(settings, statistic = "mean") {
  stopifnot(statistic %in% names(bootstrap_statistics))
  c(readLines("R/bootstrap.R", warn = FALSE, encoding = "UTF-8"), "",
    '# Placer le CSV dans ce dossier, ou télécharger la même version figée.',
    'fichier <- "maisons-quebec.csv"',
    'if (!file.exists(fichier)) download.file(',
    '  "https://donneesbleues.ca/assets/data/maisons-quebec.csv", fichier, mode = "wb")',
    'maisons <- read_bootstrap_houses(fichier)',
    sprintf('reglages <- bootstrap_settings("%s", B = %dL, confidence = %s, seed = %dL)',
      settings$variable, settings$B, settings$confidence, settings$seed),
    'resultats <- bootstrap_houses(maisons, reglages)',
    'resume <- bootstrap_summary(resultats)', 'print(resume)',
    sprintf('graphique <- bootstrap_plot(resultats, "%s")', statistic),
    'print(graphique)',
    'write_csv(resume, "bootstrap-resume.csv")',
    'write_csv(resultats$replicates, "bootstrap-repetitions.csv")',
    'ggsave("bootstrap-graphique.png", graphique, width = 9, height = 5, dpi = 160, bg = "white")')
}

ui <- fluidPage(
  title = "Bootstrap des maisons à Québec | Données bleues",
  tags$head(tags$link(rel = "stylesheet", href = "bootstrap.css")),
  tags$header(class = "app-header",
    tags$a(class = "brand", href = "https://donneesbleues.ca/", "Données bleues"),
    tags$nav("aria-label" = "Ressources associées",
      tags$a(href = "https://donneesbleues.ca/datasets/maisons-quebec/activite-bootstrap.html", "Activité"),
      tags$a(href = "https://donneesbleues.ca/resources/comprendre-intervalle-confiance.html", "Lecture"),
      tags$a(href = "https://donneesbleues.ca/datasets/maisons-quebec/fiche.html", "Données"))),
  tags$main(class = "app-main",
    tags$section(class = "app-title",
      tags$div(tags$p(class = "eyebrow", "600 MAISONS · QUÉBEC · BOOTSTRAP"),
        tags$h1("Une estimation, quelle incertitude ?"),
        tags$p("Tirer 600 lignes avec remise, calculer, recommencer. Observer la variation d’une moyenne ou d’une médiane.")),
      tags$img(src = "maisons-quebec.webp", alt = "", width = 280, height = 158)),
    tags$div(class = "workshop-layout",
      tags$aside(class = "settings", "aria-label" = "Réglages du bootstrap",
        tags$h2("1. Choisir"),
        selectInput("variable", "Mesure", choices = setNames(names(bootstrap_labels), bootstrap_labels)),
        selectInput("statistic", "Statistique à afficher", choices = c("Moyenne" = "mean", "Médiane" = "median")),
        selectInput("B", "Rééchantillonnages (B)", choices = c(500, 2000, 5000), selected = 2000),
        selectInput("confidence", "Niveau de confiance", choices = c("90 %" = 0.90, "95 %" = 0.95, "99 %" = 0.99), selected = 0.95),
        numericInput("seed", "Graine aléatoire", value = 20261003, min = 0, max = 2147483646, step = 1),
        actionButton("run", "Calculer le bootstrap", class = "calculate-button"),
        tags$p(class = "settings-note", "Les 600 maisons sont conservées. B change le nombre de calculs, pas le nombre de maisons observées."),
        tags$p(class = "pending", role = "status", textOutput("pending", inline = TRUE))),
      tags$section(class = "results", "aria-label" = "Résultats du bootstrap",
        tags$h2("2. Observer"), uiOutput("summary"),
        tabsetPanel(id = "view",
          tabPanel("Statistiques rééchantillonnées", value = "bootstrap",
            plotOutput("bootstrap_plot", height = "430px"),
            tags$p(class = "plot-caption", textOutput("caption", inline = TRUE))),
          tabPanel("Valeurs des maisons", value = "original",
            plotOutput("original_plot", height = "430px"),
            tags$p(class = "plot-caption", "Ici, chaque valeur appartient à une maison. Dans l’autre vue, chaque valeur résume un tirage de 600 lignes. Les axes s’adaptent à chaque vue.")),
          tabPanel("Un tirage", value = "sample",
            tags$div(class = "text-tab", tags$h3("Les 12 premières positions du premier tirage"),
              tags$p(textOutput("sample_note", inline = TRUE)),
              tableOutput("sample_table"),
              tags$p("Une maison peut revenir plusieurs fois ou être absente. Chaque ligne originale a la même probabilité à chaque position du tirage."))),
          tabPanel("Code R", value = "code",
            tags$div(class = "text-tab", tags$h3("Reproduire les résultats affichés"),
              tags$p("Le script complet reprend la mesure, B, le niveau, la graine et la statistique affichés. Packages : readr, dplyr, ggplot2 et scales."),
              downloadButton("code_download", "Télécharger le script R"),
              tags$pre(textOutput("code", container = tags$code))))),
        tags$div(class = "download-row", downloadButton("plot_download", "Graphique PNG"),
          downloadButton("summary_download", "Résumé CSV"),
          downloadButton("replicates_download", "Tirages CSV")))),
    tags$section(class = "interpretation",
      tags$h2("3. Interpréter"),
      tags$p(textOutput("interpretation", inline = TRUE)),
      tags$div(class = "repere-grid",
        tags$div(tags$h3("Dispersion ≠ erreur-type"),
          tags$p("L’écart-type des 600 valeurs décrit les différences entre maisons. L’erreur-type bootstrap décrit la variation de la statistique dans les tirages.")),
        tags$div(tags$h3("Plus de tirages ≠ plus de données"),
          tags$p("Augmenter B stabilise les calculs numériques. Cela ne réduit pas l’incertitude liée aux 600 observations de départ.")),
        tags$div(tags$h3("Une approximation"),
          tags$p("Le tirage initial est sans remise parmi 99 072 unités admissibles. Le bootstrap ordinaire utilisé ici néglige la petite fraction de sondage, environ 0,61 %. La couverture exacte n’est pas établie."))),
      tags$p("Le niveau nominal décrit une méthode répétée sur de nouveaux échantillons, sous ses hypothèses. L’intervalle ne délimite pas la dispersion des valeurs individuelles et ne donne pas la probabilité que le paramètre fixe appartienne aux bornes observées."),
      tags$p("Les valeurs arrondies créent des ex æquo, particulièrement visibles pour les médianes. Le bootstrap ne corrige pas les erreurs du rôle ni une population cible mal définie.")),
    tags$footer(class = "app-footer", "MAMH, extraction 2026 · Rôle 2025 · Référence au marché : 1er juillet 2023. Valeurs évaluées, sans prix de vente. ",
      tags$a(href = "https://creativecommons.org/licenses/by/4.0/deed.fr", "Données et contenus CC BY 4.0"),
      " · Code MIT · Aurélien Nicosia, Université Laval. Utilisation en classe non documentée."))
)

bootstrap_server <- function(input, output, session) {
  result <- reactiveVal(bootstrap_houses(houses, bootstrap_settings()))
  settings <- reactive(bootstrap_settings(input$variable, as.numeric(input$B),
                                         as.numeric(input$confidence), input$seed))
  statistic <- reactive({ req(input$statistic); input$statistic })
  observeEvent(input$run, {
    configuration <- tryCatch(settings(), error = function(e) NULL)
    if (is.null(configuration)) {
      showNotification("Choisir une graine entière entre 0 et 2 147 483 646.", type = "error")
      return()
    }
    withProgress(message = "Rééchantillonnage des 600 maisons…", value = 0,
      result(bootstrap_houses(houses, configuration)))
  }, ignoreInit = TRUE)
  output$pending <- renderText({
    configuration <- tryCatch(settings(), error = function(e) NULL)
    if (!identical(configuration, result()$settings))
      "Réglages modifiés : cliquer sur Calculer pour actualiser les résultats." else "Résultats à jour."
  })
  selected_summary <- reactive(bootstrap_summary(result()) |> filter(.data$statistic == statistic()))
  output$summary <- renderUI({
    summary <- selected_summary()
    digits <- if (result()$settings$variable == "aire_etages_m2") 2L else 0L
    unit <- if (digits == 2L) " m²" else " CAD"
    metric <- function(label, value) tags$div(class = "metric", tags$span(label), tags$p(value))
    tags$div(class = "summary-grid", "aria-live" = "polite",
      metric(paste(bootstrap_statistics[statistic()], "observée"),
        paste0(bootstrap_format(summary$estimate, digits), unit)),
      metric("Erreur-type bootstrap", paste0(bootstrap_format(summary$standard_error, digits), unit)),
      metric(paste0("Intervalle percentile · ", summary$confidence * 100, " %"),
        paste0(bootstrap_format(summary$lower, digits), " à ", bootstrap_format(summary$upper, digits), unit)))
  })
  output$bootstrap_plot <- renderPlot(bootstrap_plot(result(), statistic()) +
    labs(title = NULL, subtitle = NULL, caption = NULL), res = 110,
    alt = "Histogramme des statistiques bootstrap, avec estimation observée et bornes de l’intervalle percentile.")
  output$original_plot <- renderPlot(bootstrap_plot(result(), statistic(), original = TRUE) +
    labs(title = NULL, subtitle = NULL), res = 110,
    alt = "Histogramme des 600 valeurs observées, une observation par maison.")
  output$caption <- renderText(paste0(result()$settings$B, " tirages · 600 lignes par tirage · graine ",
    result()$settings$seed, ". Trait orange : statistique observée. Traits verts : intervalle pour la ",
    tolower(bootstrap_statistics[statistic()]), "; chaque barre compte des statistiques, pas des maisons."))
  output$sample_note <- renderText(paste("Le premier tirage contient 600 lignes et",
    length(unique(result()$first_indices)), "maisons distinctes. Le tableau est un extrait de ce tirage complet."))
  output$sample_table <- renderTable({
    indices <- head(result()$first_indices, 12L)
    table <- tibble(Position = seq_along(indices), Maison = houses$maison_id[indices],
                    Valeur = result()$x[indices])
    names(table)[3L] <- unname(bootstrap_labels[result()$settings$variable])
    table
  }, striped = TRUE, rownames = FALSE, digits = 2)
  output$interpretation <- renderText(paste0("La ", tolower(bootstrap_statistics[statistic()]),
    " estimée concerne les unités admissibles de cet instantané de Québec. Les résultats affichés utilisent ",
    result()$settings$B, " rééchantillonnages et un niveau nominal de ",
    100 * result()$settings$confidence, " %. Moyenne et médiane répondent à des questions différentes."))
  code <- reactive(export_bootstrap_code(result()$settings, statistic()))
  output$code <- renderText(paste(code(), collapse = "\n"))
  output$code_download <- downloadHandler("bootstrap-maisons.R",
    function(file) writeLines(code(), file, useBytes = TRUE), contentType = "text/plain; charset=utf-8")
  output$summary_download <- downloadHandler("bootstrap-resume.csv", function(file)
    write_csv(bootstrap_summary(result()) |> mutate(variable = result()$settings$variable,
      seed = result()$settings$seed), file), contentType = "text/csv; charset=utf-8")
  output$replicates_download <- downloadHandler("bootstrap-repetitions.csv", function(file)
    write_csv(result()$replicates |> mutate(variable = result()$settings$variable,
      n = result()$n, seed = result()$settings$seed), file), contentType = "text/csv; charset=utf-8")
  output$plot_download <- downloadHandler("bootstrap-graphique.png", function(file)
    ggsave(file, bootstrap_plot(result(), statistic()), device = "png",
      width = 9, height = 5, dpi = 160, bg = "white"), contentType = "image/png")
}
shinyApp(ui, bootstrap_server)
