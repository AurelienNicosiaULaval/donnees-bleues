# Lancer depuis ce dossier avec shiny::runApp().
library(shiny)
source("R/permutations.R", local = TRUE)
accidents <- read_permutation_accidents("data/accidents-quebec-2022.csv")

export_permutation_code <- function(settings) {
  c(readLines("R/permutations.R", warn = FALSE, encoding = "UTF-8"), "",
    '# Placer le CSV dans ce dossier, ou télécharger la même version figée.',
    'fichier <- "accidents-quebec-2022.csv"',
    'if (!file.exists(fichier)) download.file(',
    '  "https://donneesbleues.ca/assets/data/accidents-quebec-2022.csv", fichier, mode = "wb")',
    'accidents <- read_permutation_accidents(fichier)',
    sprintf('reglages <- permutation_settings(B = %dL, seed = %dL)', settings$B, settings$seed),
    'resultats <- permutation_accidents(accidents, reglages)',
    'resume <- permutation_summary(resultats)', 'print(resume)',
    'graphique <- permutation_plot(resultats)', 'print(graphique)',
    'write_csv(resume, "permutations-resume.csv")',
    'write_csv(resultats$replicates, "permutations-repetitions.csv")',
    'ggsave("permutations-graphique.png", graphique, width = 9, height = 5, dpi = 160, bg = "white")')
}

ui <- fluidPage(
  title = "Accidents au Québec : comparer par permutation | Données bleues",
  tags$head(tags$link(rel = "stylesheet", href = "permutations.css"),
    tags$script(src = "downloads.js", defer = NA)),
  tags$header(class = "app-header",
    tags$a(class = "brand", href = "https://donneesbleues.ca/", "Données bleues"),
    tags$nav("aria-label" = "Ressources associées",
      tags$a(href = "https://donneesbleues.ca/datasets/rapports-accident/activite-permutation.html", "Activité"),
      tags$a(href = "https://donneesbleues.ca/resources/comprendre-p-valeur.html", "Lecture"),
      tags$a(href = "https://donneesbleues.ca/datasets/rapports-accident/fiche.html", "Données"))),
  tags$main(class = "app-main",
    tags$section(class = "app-title",
      tags$div(tags$p(class = "eyebrow", "QUÉBEC · ACCIDENTS RAPPORTÉS · 2022"),
        tags$h1("Deux proportions, un écart à comprendre"),
        tags$p("Les accidents avec victimes sont-ils aussi fréquents parmi les rapports de la semaine et de la fin de semaine ? Mélanger les statuts de victime et comparer.")),
      tags$img(src = "rapports-accident.webp", alt = "", width = 280, height = 158)),
    tags$div(class = "workshop-layout",
      tags$aside(class = "settings", "aria-label" = "Réglages des permutations",
        tags$h2("1. Simuler"),
        selectInput("B", "Permutations (B)", choices = c(500, 2000, 5000, 20000), selected = 2000),
        numericInput("seed", "Graine aléatoire", value = 20261003, min = 0, max = 2147483646, step = 1),
        actionButton("run", "Calculer les permutations", class = "calculate-button"),
        tags$p(class = "settings-note", "Test bilatéral : les écarts dans les deux directions comptent. Chaque mélange conserve les 108 186 rapports, les effectifs des groupes et le total des accidents avec victimes."),
        tags$p(class = "pending", role = "status", textOutput("pending", inline = TRUE))),
      tags$section(class = "results", "aria-label" = "Résultats des permutations",
        tags$h2("2. Observer"), uiOutput("summary"),
        tabsetPanel(id = "view",
          tabPanel("Permutations", value = "permutations",
            plotOutput("permutation_plot", height = "430px"),
            tags$p(class = "plot-caption", textOutput("caption", inline = TRUE))),
          tabPanel("Proportions observées", value = "observed",
            plotOutput("observed_plot", height = "430px"),
            tableOutput("counts")),
          tabPanel("Un mélange", value = "sample",
            tags$div(class = "text-tab", tags$h3("Les 12 premières lignes du premier mélange"),
              tags$p("Les groupes de jours restent fixes. Seuls les statuts avec ou sans victimes sont réaffectés entre les lignes, sans remise."),
              tableOutput("sample_table"),
              tags$h3("Vérifier les quantités conservées"), tableOutput("mixed_counts"))),
          tabPanel("Code R", value = "code",
            tags$div(class = "text-tab", tags$h3("Reproduire les résultats affichés"),
              tags$p("Le script complet reprend B et la graine du dernier calcul. Packages : readr, dplyr, ggplot2 et scales."),
              downloadButton("code_download", "Télécharger le script R"),
              tags$pre(textOutput("code", container = tags$code))))),
        tags$div(class = "download-row", downloadButton("plot_download", "Graphique PNG"),
          downloadButton("summary_download", "Résumé CSV"),
          downloadButton("replicates_download", "Permutations CSV")),
        tags$p(id = "download-status", class = "plot-caption", role = "status"))),
    tags$section(class = "interpretation",
      tags$h2("3. Interpréter"), tags$p(textOutput("interpretation", inline = TRUE)),
      tags$div(class = "repere-grid",
        tags$div(tags$h3("Une différence mesurée"),
          tags$p("L’écart est exprimé en points de pourcentage. Une p-valeur ne mesure ni la taille de cet écart ni son importance pratique.")),
        tags$div(tags$h3("Un modèle à discuter"),
          tags$p("Sous le modèle nul, les statuts de victime sont échangeables entre tous les rapports, à marges fixes. Cette hypothèse n’est pas garantie : météo, régions, heures et regroupements peuvent intervenir.")),
        tags$div(tags$h3("Aucun trajet observé"),
          tags$p("La proportion porte sur les accidents rapportés. Sans nombre de trajets ou distance parcourue, on ne calcule pas le risque d’avoir un accident."))),
      tags$p(textOutput("resolution_note", inline = TRUE)),
      tags$p("La référence exacte somme la loi hypergéométrique pour le même critère bilatéral |écart|, égalités incluses. Elle évite l’erreur Monte-Carlo, mais conserve les hypothèses du modèle. Les différences du fichier se décrivent directement; une p-valeur n’est pas nécessaire pour constater leur existence.")),
    tags$footer(class = "app-footer", "SAAQ · Rapports publiés pour 2022 · Version figée 1.0.0. ",
      tags$a(href = "https://www.donneesquebec.ca/recherche/dataset/rapports-d-accident", "Source officielle"),
      " · Données et contenus CC BY 4.0 · Code MIT · Aurélien Nicosia, Université Laval. Utilisation en classe non documentée."))
)

permutation_server <- function(input, output, session) {
  result <- reactiveVal(permutation_accidents(accidents, permutation_settings()))
  settings <- reactive(permutation_settings(as.numeric(input$B), input$seed))
  observeEvent(input$run, {
    configuration <- tryCatch(settings(), error = function(e) NULL)
    if (is.null(configuration)) {
      showNotification("Choisir une graine entière entre 0 et 2 147 483 646.", type = "error")
      return()
    }
    withProgress(message = "Calcul des permutations…", value = 0,
      result(permutation_accidents(accidents, configuration)))
  }, ignoreInit = TRUE)
  output$pending <- renderText({
    configuration <- tryCatch(settings(), error = function(e) NULL)
    if (!identical(configuration, result()$settings))
      "Réglages modifiés : cliquer sur Calculer pour actualiser les résultats." else "Résultats à jour."
  })
  output$summary <- renderUI({
    summary <- permutation_summary(result())
    metric <- function(label, value) tags$div(class = "metric", tags$span(label), tags$p(value))
    tags$div(class = "summary-grid", "aria-live" = "polite",
      metric("Écart FDS − semaine", paste0(permutation_format(summary$difference_pp), " points")),
      metric("p-valeur Monte-Carlo", permutation_p_format(summary$p_mc)),
      metric("p-valeur de référence exacte", permutation_p_format(summary$p_exact)))
  })
  output$permutation_plot <- renderPlot(permutation_plot(result()) +
    labs(title = NULL, subtitle = NULL, caption = NULL), res = 110,
    alt = "Histogramme des écarts obtenus par permutation, avec les deux seuils du test bilatéral en orange.")
  output$observed_plot <- renderPlot(permutation_plot(result(), observed = TRUE) +
    labs(title = NULL, caption = NULL), res = 110,
    alt = "Proportions d’accidents avec victimes parmi les rapports de chaque groupe de jours.")
  output$caption <- renderText({
    s <- permutation_summary(result())
    paste0(s$extreme, " mélanges au moins aussi extrêmes sur ", s$B, ". Graine : ", s$seed,
      ". Orange plein : écart observé; orange pointillé : seuil opposé. Les barres comptent des mélanges.")
  })
  counts_table <- function(counts) {
    tibble(Groupe = counts$label, Rapports = counts$n, `Avec victimes` = counts$victims,
      `Proportion (%)` = round(100 * counts$proportion, 2))
  }
  output$counts <- renderTable(counts_table(result()$counts), striped = TRUE, digits = 2)
  output$sample_table <- renderTable({
    first <- head(result()$first, 12L)
    tibble(Position = first$position, Groupe = unname(accident_groups[first$group]),
      `Victimes avant` = ifelse(first$observed_victim, "Oui", "Non"),
      `Victimes après` = ifelse(first$permuted_victim, "Oui", "Non"))
  }, striped = TRUE)
  output$mixed_counts <- renderTable(counts_table(permutation_counts(tibble(
    group = result()$first$group, victim = result()$first$permuted_victim))), striped = TRUE, digits = 2)
  output$interpretation <- renderText({
    s <- permutation_summary(result())
    paste0("Parmi les rapports publiés, ", permutation_format(100 * s$proportion_weekday),
      " % des accidents en semaine comportent des victimes, contre ",
      permutation_format(100 * s$proportion_weekend), " % la fin de semaine. L’écart de ",
      permutation_format(s$difference_pp), " point(s) est peu compatible avec le modèle de mélange complet. Cela ne démontre ni une cause ni un risque par trajet plus élevé.")
  })
  output$resolution_note <- renderText({
    s <- permutation_summary(result())
    paste0("Calcul Monte-Carlo : (", s$extreme, " + 1) / (", s$B, " + 1). La plus petite valeur possible est ",
      permutation_p_format(s$resolution), ". Aucun mélange extrême ne signifie pas p = 0. Augmenter B affine la résolution sans ajouter de rapports.")
  })
  code <- reactive(export_permutation_code(result()$settings))
  output$code <- renderText(paste(code(), collapse = "\n"))
  output$code_download <- downloadHandler("permutations-accidents.R",
    function(file) writeLines(code(), file, useBytes = TRUE), contentType = "text/plain; charset=utf-8")
  output$summary_download <- downloadHandler("permutations-resume.csv",
    function(file) write_csv(permutation_summary(result()), file), contentType = "text/csv; charset=utf-8")
  output$replicates_download <- downloadHandler("permutations-repetitions.csv",
    function(file) write_csv(result()$replicates |> mutate(seed = result()$settings$seed), file),
    contentType = "text/csv; charset=utf-8")
  output$plot_download <- downloadHandler("permutations-graphique.png", function(file)
    ggsave(file, permutation_plot(result()), device = "png", width = 9, height = 5,
      dpi = 160, bg = "white"), contentType = "image/png")
}
shinyApp(ui, permutation_server)
