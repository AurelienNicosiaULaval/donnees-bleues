# Launch from this directory with shiny::runApp().
suppressPackageStartupMessages({
  library(shiny)
  library(bslib)
  library(ggplot2)
  library(dplyr)
  library(readr)
})

source("R/builder.R", local = TRUE)
trees <- read_trees("data/arbres_quebec.csv")
stopifnot(nrow(trees) == 200L, all(table(trees$species_fr) == 50L))

step_help <- c(
  "ggplot() choisit les données. aes() associe les variables aux axes. Il manque encore une couche pour dessiner les observations.",
  "Une fonction geom_*() transforme les variables en marques visibles : points, boîtes, violons ou distributions.",
  "Dans aes(), une couleur dépend d’une variable. En dehors de aes(), elle reste fixe. Une échelle choisit la palette.",
  "Ajoutez les observations, une moyenne ou des facettes. Chaque couche doit aider à lire les données.",
  "labs() nomme le graphique et les axes. theme() règle sa présentation. Téléchargez le code pour refaire vos choix dans R."
)

ui <- page_fluid(
  title = "ggplot builder | Données bleues", lang = "fr",
  theme = bs_theme(version = 5, bg = "#F4F7FA", fg = "#172B3A",
                   primary = "#095C88", base_font = "system-ui"),
  tags$head(tags$link(rel = "icon", type = "image/svg+xml", href = "favicon.svg"),
            tags$link(rel = "stylesheet", href = "builder.css"),
            tags$script(src = "builder.js")),
  tags$header(class = "masthead",
    tags$a(href = "https://donneesbleues.ca", class = "brand", "données", tags$span("bleues")),
    tags$span(class = "masthead-label", "L’atelier des graphiques"),
    tags$a(href = "https://aureliennicosia.shinyapps.io/TutorielGGplot/",
           target = "_blank", rel = "noopener", class = "old-link", "Le tutoriel d’origine ↗")
  ),
  tags$main(class = "workshop",
    tags$section(class = "intro",
      tags$div(
        tags$p(class = "eyebrow", "QUÉBEC · FORÊT · APPRENDRE EN EXPLORANT"),
        tags$h1("Votre premier beau ", tags$span("ggplot.")),
        tags$p(class = "intro-copy", "Choisissez. Observez. Comprenez le code. Un graphique prend forme, couche après couche.")
      ),
      tags$div(class = "dataset-badge", tags$span(class = "tree-icon", "♧"),
        tags$div(tags$strong("200 arbres du Québec"), tags$span("4 espèces · relevés de 2015 à 2025")))
    ),
    tags$div(class = "preset-row", tags$span("Un point de départ"),
      actionButton("preset_portrait", "Portrait forestier", class = "preset"),
      actionButton("preset_points", "Diamètre et hauteur", class = "preset"),
      actionButton("preset_densite", "Distributions", class = "preset"),
      actionButton("preset_debut", "Partir de zéro", class = "preset")
    ),
    tags$div(class = "builder-grid",
      tags$aside(class = "controls-panel", `aria-label` = "Réglages du graphique",
        tags$div(class = "panel-heading", tags$span(class = "section-number", "01"), tags$h2("Composer")),
        selectInput("mode", "La forme du graphique", choices = setNames(names(mode_labels), mode_labels), selected = "portrait"),
        conditionalPanel("input.mode === 'points'",
          selectInput("x", "Axe horizontal", choices = setNames(names(variable_labels), variable_labels), selected = "diametre_cm")),
        selectInput("y", "La mesure à explorer", choices = setNames(names(variable_labels), variable_labels), selected = "hauteur_m"),
        conditionalPanel("input.mode === 'portrait' || input.mode === 'violon'",
          checkboxInput("points", "Montrer chaque arbre", TRUE),
          checkboxInput("mean", "Ajouter la moyenne (losange)", TRUE),
          checkboxInput("flip", "Passer à l’horizontale", TRUE)),
        conditionalPanel("input.mode === 'points'",
          checkboxInput("smooth", "Ajouter une droite descriptive", FALSE)),
        conditionalPanel("input.mode !== 'portrait' && input.mode !== 'violon'",
          checkboxInput("facet", "Un panneau par espèce", FALSE)),
        conditionalPanel("input.mode === 'histogramme'",
          sliderInput("bins", "Nombre de classes", min = 5, max = 40, value = 18, step = 1)),
        tags$details(open = TRUE,
          tags$summary("Couleurs et style"),
          checkboxInput("colour", "Associer une couleur à l’espèce", TRUE),
          selectInput("palette", "Palette", choices = c("Forêt québécoise" = "foret", "Données bleues" = "bleue", "Okabe-Ito" = "accessible")),
          selectInput("theme", "Thème", choices = c("Données bleues" = "bleues", "Minimal" = "minimal", "Classique" = "classic", "Gris ggplot2" = "gray")),
          sliderInput("alpha", "Opacité", min = 0.1, max = 1, value = 0.65, step = 0.05),
          conditionalPanel("input.mode === 'points' || input.mode === 'portrait' || input.mode === 'violon'",
            sliderInput("size", "Taille des points", min = 1, max = 5, value = 2.5, step = 0.25))
        ),
        tags$details(tags$summary("Titres et sélection"),
          textInput("title", "Titre", "Quatre espèces, quatre silhouettes", width = "100%"),
          textInput("subtitle", "Sous-titre", "Comparer les hauteurs en gardant chaque arbre visible"),
          checkboxGroupInput("species", "Espèces à garder", choices = species_labels, selected = species_labels)
        ),
        tags$p(class = "control-hint", "Les réglages apparaissent à l’étape correspondante au-dessus du graphique.")
      ),
      tags$section(class = "canvas-panel", `aria-label` = "Graphique et code",
        tags$div(class = "canvas-top", tags$div(tags$span(class = "section-number", "02"), tags$h2("Voir les couches")),
          uiOutput("sample_count")),
        radioButtons("stage", NULL, choices = c("1 · Données" = 1, "2 · Géométrie" = 2,
          "3 · Couleurs" = 3, "4 · Couches" = 4, "5 · Finition" = 5), selected = 5, inline = TRUE),
        tags$div(class = "stage-help", textOutput("step_help")),
        uiOutput("data_warning"),
        navset_card_tab(
          id = "view_tab",
          nav_panel("Le graphique", value = "plot", plotOutput("plot", height = "540px")),
          nav_panel("Le code ggplot2", value = "code",
            tags$div(class = "code-intro", "Ce code produit exactement le graphique affiché. Le fichier .R inclut aussi l’importation des données."),
            tags$button(type = "button", id = "copy-code", class = "btn btn-outline-primary btn-sm", "Copier le code"),
            verbatimTextOutput("code", placeholder = TRUE)),
          nav_panel("Les données", value = "data",
            tags$p(class = "code-intro", "Les dix premières lignes utilisées dans ce graphique. Le CSV téléchargeable conserve les 200 arbres et les 21 colonnes de la source."),
            tableOutput("data_preview"))
        ),
        tags$div(class = "export-row",
          downloadButton("download_r", "Le code R", class = "btn-primary"),
          downloadButton("download_png", "Le graphique PNG"),
          downloadButton("download_data", "Les données CSV"),
          tags$span("Votre graphique, à emporter.")
        )
      )
    ),
    tags$section(class = "learning-grid",
      tags$div(class = "challenge-card",
        tags$p(class = "eyebrow", "À VOUS DE JOUER"), tags$h2("Trois petits défis"),
        tags$ol(
          tags$li("Revenez à « 1 · Données », puis avancez jusqu’à « 5 · Finition ». Repérez la nouvelle ligne de code à chaque étape."),
          tags$li("Comparez une boîte seule avec une boîte accompagnée de tous les arbres. Que révèle la seconde version ?"),
          tags$li("Explorez l’âge, puis regardez les données exclues. Pourquoi l’érable rouge disparaît-il ?")
        ),
        tags$details(tags$summary("Un indice pour le dernier défi"),
          tags$p("L’âge manque pour les 50 érables rouges, ainsi que pour deux autres arbres. Supprimer les âges manquants retire donc une espèce entière; aucune valeur n’est imputée ici."))
      ),
      tags$div(class = "source-card",
        tags$p(class = "eyebrow", "LES DONNÉES DERRIÈRE LE VISUEL"),
        tags$h2("Un arbre, une observation"),
        tags$p("Ce jeu pédagogique contient 50 arbres par espèce, provenant de 200 placettes distinctes. Ce choix facilite les comparaisons; la représentativité provinciale n’est pas établie."),
        tags$p("Les densités utilisent une largeur de bande automatique. La droite est un résumé descriptif. Les moyennes et les graphiques décrivent les arbres retenus."),
        tags$a(href = "https://github.com/AurelienNicosiaULaval/arbres_quebec/releases/tag/v1.0.0",
               target = "_blank", rel = "noopener", "Source, provenance et limites ↗"),
        tags$p(class = "licence-note", "MRNF / PET5 · jeu dérivé : Aurélien Nicosia · v1.0.0\nDonnées : CC BY 4.0 · taxonomie VASCAN : CC0 1.0")
      )
    )
  ),
  tags$footer(class = "footer", "Données bleues · Aurélien Nicosia · Université Laval", tags$span("Explorer pour comprendre."))
)

server <- function(input, output, session) {
  configuration <- reactive({
    req(input$mode, input$x, input$y, input$stage, input$palette, input$theme,
        input$alpha, input$size, input$bins)
    list(mode = input$mode, x = input$x, y = input$y, palette = input$palette,
      theme = input$theme, species = input$species, stage = as.integer(input$stage),
      alpha = input$alpha, size = input$size, bins = as.integer(input$bins),
      points = isTRUE(input$points), mean = isTRUE(input$mean), smooth = isTRUE(input$smooth),
      facet = isTRUE(input$facet), flip = isTRUE(input$flip), colour = isTRUE(input$colour),
      title = input$title, subtitle = input$subtitle,
      compact = !is.null(session$clientData$output_plot_width) &&
        session$clientData$output_plot_width < 600)
  })
  view <- reactive(build_view(configuration(), trees))

  output$step_help <- renderText(step_help[as.integer(input$stage)])
  output$sample_count <- renderUI(tags$span(class = "count-chip", paste(nrow(view()$data), "arbres retenus")))
  output$data_warning <- renderUI({
    v <- view()
    if (!v$selected) return(tags$div(class = "data-warning", "Sélectionnez au moins une espèce dans « Titres et sélection »."))
    if (v$excluded > 0) return(tags$div(class = "data-warning", role = "status",
      paste0(v$excluded, " arbre(s) exclu(s) : mesure manquante. "),
      if (input$y == "age_ans" || (input$mode == "points" && input$x == "age_ans"))
        "L’âge est absent pour tous les érables rouges. Le graphique ne représente donc pas les quatre espèces."))
    if (input$mode == "points" && input$x == input$y) return(tags$div(class = "data-warning",
      "Les deux axes montrent la même mesure. Choisissez deux variables différentes pour explorer leur relation."))
    if (input$mode == "histogramme" && isTRUE(input$colour) && !isTRUE(input$facet) && as.integer(input$stage) >= 3)
      return(tags$div(class = "gentle-note", "Les histogrammes se superposent. Essayez un panneau par espèce pour mieux comparer."))
    NULL
  })
  output$plot <- renderPlot({
    validate(need(nrow(view()$data) > 0, "Aucune observation disponible pour ces choix."))
    view()$plot
  }, res = 120, alt = reactive(paste("Graphique", mode_labels[[input$mode]],
      "de", variable_labels[[input$y]], "sur", nrow(view()$data), "arbres sélectionnés.")))
  output$code <- renderText(view()$code)
  output$data_preview <- renderTable({
    view()$data |> select(espece, diametre_cm, hauteur_m, age_ans, survey_year) |> head(10)
  }, digits = 1, striped = TRUE, bordered = FALSE, na = "Manquant")

  # Presets update every relevant control so their results are reproducible.
  set_preset <- function(mode, stage = 5L) {
    updateSelectInput(session, "mode", selected = mode)
    updateSelectInput(session, "x", selected = "diametre_cm")
    updateSelectInput(session, "y", selected = "hauteur_m")
    updateSelectInput(session, "palette", selected = "foret")
    updateSelectInput(session, "theme", selected = "bleues")
    updateRadioButtons(session, "stage", selected = stage)
    updateCheckboxGroupInput(session, "species", selected = species_labels)
    for (id in c("points", "mean", "flip", "colour")) updateCheckboxInput(session, id, value = TRUE)
    updateCheckboxInput(session, "smooth", value = FALSE)
    updateCheckboxInput(session, "facet", value = mode == "densite")
    updateSliderInput(session, "alpha", value = 0.65)
    updateSliderInput(session, "size", value = 2.5)
    updateSliderInput(session, "bins", value = 18)
    labels <- switch(mode,
      portrait = c("Quatre espèces, quatre silhouettes", "Comparer les hauteurs en gardant chaque arbre visible"),
      points = c("Grandir en hauteur et en diamètre", "Chaque point représente un arbre; la couleur indique son espèce"),
      densite = c("Des hauteurs qui se distribuent autrement", "Une courbe par espèce, des axes communs pour comparer"))
    updateTextInput(session, "title", value = labels[1])
    updateTextInput(session, "subtitle", value = labels[2])
    nav_select("view_tab", "plot", session = session)
  }
  observeEvent(input$preset_portrait, set_preset("portrait"))
  observeEvent(input$preset_points, set_preset("points"))
  observeEvent(input$preset_densite, set_preset("densite"))
  observeEvent(input$preset_debut, set_preset("portrait", 1L))

  output$download_r <- downloadHandler(
    filename = function() "mon-graphique-donnees-bleues.R",
    content = function(file) writeLines(export_script(configuration()), file, useBytes = TRUE),
    contentType = "text/plain; charset=utf-8")
  output$download_png <- downloadHandler(
    filename = function() "mon-graphique-donnees-bleues.png",
    content = function(file) {
      req(nrow(view()$data) > 0)
      ggsave(file, view()$plot, width = 11, height = 7, dpi = 180, bg = "white", device = "png")
    }, contentType = "image/png")
  output$download_data <- downloadHandler(filename = function() "arbres_quebec-v1.0.0.csv",
    content = function(file) file.copy("data/arbres_quebec.csv", file),
    contentType = "text/csv; charset=utf-8")
}

shinyApp(ui, server)
