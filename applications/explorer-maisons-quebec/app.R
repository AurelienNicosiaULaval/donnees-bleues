# Lancer depuis ce dossier : shiny::runApp()
library(shiny)
source("R/helpers.R", local = TRUE)

houses <- read_houses()
year_range <- range(houses$annee_construction)
choices <- stats::setNames(names(variable_labels), unname(variable_labels))
tutorial_url <- "https://donneesbleues.ca/resources/tutoriel-maisons-quebec.html"
dataset_url <- "https://donneesbleues.ca/datasets/maisons-quebec/fiche.html"

ui <- fluidPage(
  tags$head(tags$link(rel = "stylesheet", type = "text/css", href = "explorer.css")),
  tags$header(class = "app-header",
    tags$a(class = "brand", href = "https://donneesbleues.ca/", "Données bleues"),
    tags$nav("aria-label" = "Ressources associées",
      tags$a(href = tutorial_url, "Tutoriel"), tags$a(href = dataset_url, "Fiche des données"))),
  tags$main(class = "app-main",
    tags$section(class = "app-title",
      tags$div(tags$h1("Explorer les maisons à Québec"),
        tags$p("Comparer les superficies, les types de maisons et les valeurs au rôle.")),
      tags$img(src = "maisons-quebec.webp", alt = "", width = 280, height = 158)),
    tabsetPanel(id = "section",
      tabPanel("Explorer", value = "explore",
        tags$div(class = "explorer-layout",
          tags$aside(class = "settings",
            selectInput("graph", "Graphique", choices = c("Nuage de points" = "scatter",
              "Histogramme" = "histogram", "Boîtes à moustaches" = "boxplot")),
            selectInput("y", "Variable à étudier", choices, selected = "valeur_fonciere_cad"),
            conditionalPanel("input.graph === 'scatter'",
              selectInput("x", "Variable horizontale", choices, selected = "aire_etages_m2")),
            checkboxInput("log_axes", "Échelles logarithmiques", TRUE),
            conditionalPanel("input.graph === 'histogram'",
              sliderInput("bins", "Nombre de classes", min = 5, max = 60, value = 30, step = 1)),
            checkboxGroupInput("types", "Types de maisons", house_types, selected = house_types),
            sliderInput("years", "Année de construction", min = year_range[[1]],
              max = year_range[[2]], value = year_range, step = 1, sep = ""),
            actionButton("reset", "Réinitialiser", class = "reset-button")),
          tags$section(class = "results", "aria-label" = "Résultats de l’exploration",
            uiOutput("summary"), plotOutput("house_plot", height = "510px"),
            tags$p(class = "plot-caption", textOutput("caption", inline = TRUE)),
            tags$div(class = "observation",
              tags$h2("À observer"), tags$p(textOutput("question", inline = TRUE))),
            tags$div(class = "download-row",
              downloadButton("download_plot", "Télécharger le graphique"),
              downloadButton("download_data", "Télécharger les données filtrées"))))),
      tabPanel("Données", value = "data",
        tags$section(class = "text-tab", tags$h2("Les maisons retenues"),
          tags$p(textOutput("table_note", inline = TRUE)),
          tags$div(class = "data-table", tableOutput("house_table")),
          downloadButton("download_data_table", "Télécharger les données filtrées"))),
      tabPanel("Code R", value = "code",
        tags$section(class = "text-tab", tags$h2("Reproduire vos choix dans R"),
          tags$p("Le script reprend les filtres, le graphique et l’échelle sélectionnés. Il lit le CSV de la version 1.0.0 et peut le télécharger s’il est absent."),
          downloadButton("download_code", "Télécharger le script R"),
          tags$pre(class = "code-block", textOutput("code", container = tags$code)))),
      tabPanel("Repères", value = "notes",
        tags$section(class = "text-tab reading-tab",
          tags$h2("Comprendre ce que l’on compare"),
          tags$h3("Une ligne, une maison"),
          tags$p("Le jeu contient 600 unités à un logement tirées parmi 99 072 unités admissibles de la ville de Québec. Les logements détachés, jumelés et en rangée sont inclus selon les critères documentés."),
          tags$h3("Valeurs au rôle et superficies"),
          tags$p("Les valeurs sont des évaluations foncières, sans prix de vente observés. L’aire d’étages est brute; elle peut notamment inclure un garage intégré."),
          tags$h3("Changer d’échelle"),
          tags$p("Sur une échelle logarithmique, des rapports égaux occupent des distances égales. Les logarithmes nécessitent des valeurs strictement positives. Le nombre de lignes exclues du graphique est indiqué sous celui-ci."),
          tags$p("Pour un histogramme logarithmique, les classes sont équidistantes après transformation logarithmique. Les résumés de valeur et d’aire restent calculés dans les unités originales."),
          tags$h3("Décrire et interpréter"),
          tags$p("Une association ne démontre pas une relation causale. Filtrer les maisons change le groupe décrit. Aucune valeur extrême n’est retirée automatiquement."),
          tags$p("Les boîtes à moustaches sont calculées à partir des valeurs dans l’échelle choisie; toutes les observations utilisables sont superposées. Les formes des boîtes seules ne renseignent pas sur la taille des groupes."),
          tags$h3("Sources et réutilisation"),
          tags$p("Source : MAMH, rôle 2025 de Québec, extraction 2026, référence au marché le 1er juillet 2023. Données CC BY 4.0; code original MIT. Application par Aurélien Nicosia, Université Laval."),
          tags$p("Sources et scripts vérifiés techniquement; utilisation en classe non documentée."),
          tags$a(href = dataset_url, "Lire le dictionnaire, la méthode et les limites"),
          tags$p(tags$a(href = tutorial_url, "Suivre le tutoriel guidé")))))),
  tags$footer(class = "app-footer",
    "Valeurs évaluées, pas prix de vente. Rôle 2025, référence au marché : 1er juillet 2023. Source : MAMH · ",
    tags$a(href = "https://creativecommons.org/licenses/by/4.0/deed.fr", "CC BY 4.0"), ".")
)

explorer_server <- function(input, output, session) {
  settings <- reactive({
    req(input$years, input$graph, input$x, input$y)
    explorer_settings(input$types, input$years, input$graph, input$x, input$y,
      isTRUE(input$log_axes), if (is.null(input$bins)) 30L else input$bins)
  })
  selected <- reactive(filter_houses(houses, settings()))
  plot_data <- reactive(plot_houses(selected(), settings()))
  output$summary <- renderUI({
    summary <- house_summary(selected())
    tags$div(class = "summary-row", "aria-live" = "polite",
      tags$span(class = "summary-count", paste(summary$n, "maisons retenues")),
      tags$span(paste0("Valeur médiane : ", format_number_fr(summary$value), " CAD")),
      tags$span(paste0("Aire médiane : ", format_number_fr(summary$area, 2), " m²")))
  })
  output$house_plot <- renderPlot({
    validate(need(nrow(plot_data()) > 0, "Aucune observation pour ces choix. Modifier les filtres ou réinitialiser."))
    make_house_plot(selected(), settings())
  }, res = 110, alt = "Graphique des maisons sélectionnées; les variables et les échelles sont indiquées sur les axes.")
  output$caption <- renderText(plot_caption(selected(), settings()))
  output$question <- renderText(observation_question(settings()$graph))
  output$code <- renderText(export_house_code(settings()))
  output$table_note <- renderText(paste(nrow(selected()),
    "maisons retenues. Les 100 premières lignes et huit colonnes sont affichées.",
    "Le CSV téléchargeable contient toutes les lignes retenues et les 19 colonnes."))
  output$house_table <- renderTable({
    validate(need(nrow(selected()) > 0, "Aucune maison retenue."))
    selected() |> select(maison_id, lien_physique, annee_construction, aire_etages_m2,
      superficie_terrain_m2, valeur_fonciere_cad, arrondissement_code, voisinage_code) |> head(100)
  }, striped = TRUE, bordered = FALSE, spacing = "s", rownames = FALSE, digits = 2, na = "NA")
  csv_content <- function(file) write_csv(selected(), file)
  output$download_data <- downloadHandler(filename = function() "maisons-filtrees.csv",
    content = csv_content, contentType = "text/csv; charset=utf-8")
  output$download_data_table <- downloadHandler(filename = function() "maisons-filtrees.csv",
    content = csv_content, contentType = "text/csv; charset=utf-8")
  output$download_plot <- downloadHandler(filename = function() "maisons-graphique.png",
    content = function(file) {
      req(nrow(plot_data()) > 0)
      ggsave(file, make_house_plot(selected(), settings()), device = "png",
        width = 9, height = 5.5, dpi = 160, bg = "white")
    }, contentType = "image/png")
  output$download_code <- downloadHandler(filename = function() "explorer-maisons-quebec.R",
    content = function(file) writeLines(export_house_code(settings()), file, useBytes = TRUE),
    contentType = "text/plain; charset=utf-8")
  observeEvent(input$reset, {
    updateSelectInput(session, "graph", selected = "scatter")
    updateSelectInput(session, "x", selected = "aire_etages_m2")
    updateSelectInput(session, "y", selected = "valeur_fonciere_cad")
    updateCheckboxInput(session, "log_axes", value = TRUE)
    updateCheckboxGroupInput(session, "types", selected = house_types)
    updateSliderInput(session, "years", value = year_range)
    updateSliderInput(session, "bins", value = 30L)
  })
}
shinyApp(ui, explorer_server)
