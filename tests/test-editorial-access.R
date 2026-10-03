# The compact renderer must preserve access conditions and actual file versions.
library(xml2)
source('R/utils_dataset_page.R')
source('R/utils_catalogue_ui.R')

local({
  original_context <- dataset_current_context
  on.exit(assign('dataset_current_context', original_context, envir = .GlobalEnv))
  for (id in c('bixi', 'arbres-quebec', 'vehicules-canada-2025',
               'empress-of-ireland', 'retards-transport-collectif', 'ulaval-programmes-cours',
               'vols-montreal-trudeau')) {
    assign('dataset_current_context', function() list(root = '.',
      dataset_dir = file.path('datasets', id), relative_root = '../..'), envir = .GlobalEnv)
    html <- paste(capture.output({render_dataset_detail_header(); render_dataset_detail_footer()}), collapse = '\n')
    doc <- read_html(html)
    meta <- yaml::read_yaml(file.path('datasets', id, 'metadata.yml'))
    receipt <- jsonlite::read_json(paste0('assets/classroom/', id, '.zip.json'))
    stopifnot(length(xml_find_all(doc, '//h1')) == 1L,
              length(xml_find_all(doc, '//details[@id="documentation"]')) == 1L,
              !grepl('Pour travailler', html, fixed = TRUE))
    # Download and restrictions must be outside the collapsed documentation.
    download <- xml_find_all(doc, '//header//a[@download]')
    stopifnot(length(download) == 1L,
              xml_attr(download, 'href') == paste0('../../assets/classroom/', id, '.zip'))
    if (receipt$mode != 'frozen') stopifnot(length(xml_find_all(doc,
      '//p[@class="dataset-access-condition" and not(ancestor::details)]')) == 1L)
    dates <- xml_attr(xml_find_all(doc, '//dl[contains(@class,"resource-dates")]//time'), 'datetime')
    stopifnot(identical(dates, c(meta$date_added, meta$date_updated)))
    if (id == 'bixi') stopifnot(grepl('1 113 lignes, 10 variables', xml_text(doc), fixed = TRUE))
    if (id == 'arbres-quebec') stopifnot(grepl('Version fixe 1.0.0', xml_text(doc), fixed = TRUE))
    if (id == 'vols-montreal-trudeau') {
      activity <- xml_find_first(doc, '//article[contains(@class,"dataset-activity-card")]')
      stopifnot(grepl('Aperçu de 120 jours du calendrier quotidien', xml_text(doc), fixed = TRUE),
                grepl('Fichiers inclus', xml_text(activity), fixed = TRUE),
                !grepl('Acquisition préalable', xml_text(activity), fixed = TRUE))
    }
  }
})

# Attribute names must not inherit an R vector's dataset-name suffix.
attrs <- catalogue_attributes(c(license = unname(c(bixi = 'CC BY 4.0')),
                                title = '<texte "cité">'))
node <- xml_find_first(read_html(paste0('<article', attrs, '></article>')), '//article')
stopifnot(xml_attr(node, 'data-license') == 'CC BY 4.0',
          xml_attr(node, 'data-title') == '<texte "cité">',
          editorial_license('CC-BY 4.0, vérifiée le 2026-06-21') == 'CC BY 4.0',
          editorial_license('Aucune licence ouverte explicite') == 'Réutilisation à valider')
message('Accès, versions, dates et encodage des fiches simplifiées : vérifiés.')

# A dictionary or summary appearing first must not supply the observation count.
local({
  expected <- c('budgets-municipaux-quebec' = '1 105 lignes, 31 variables',
                'pyramides-ages' = '84 lignes, 8 variables',
                'qualite-air' = '245 lignes, 13 variables',
                'qualite-air-horaire' = '46 723 lignes, 13 variables')
  original_context <- dataset_current_context
  on.exit(assign('dataset_current_context', original_context, envir = .GlobalEnv))
  for (id in names(expected)) {
    meta <- yaml::read_yaml(file.path('datasets', id, 'metadata.yml'))
    receipt <- jsonlite::read_json(paste0('assets/classroom/', id, '.zip.json'))
    primary <- dataset_primary_kit_table(meta, receipt)
    reordered <- receipt
    reordered$tables <- rev(receipt$tables)
    stopifnot(identical(primary$path, meta$processed_file),
              identical(primary, dataset_primary_kit_table(meta, reordered)))
    assign('dataset_current_context', function() list(root = '.',
      dataset_dir = file.path('datasets', id), relative_root = '../..'), envir = .GlobalEnv)
    doc <- read_html(paste(capture.output(render_dataset_detail_header()), collapse = '\n'))
    version <- xml_text(xml_find_first(doc, '//p[@class="dataset-version"]'))
    stopifnot(grepl(expected[[id]], version, fixed = TRUE),
              grepl(meta$publication$classroom$primary_label, version, fixed = TRUE))
    if (id == 'qualite-air-horaire') {
      unit <- xml_text(xml_find_first(doc, '//dl/div[dt="Une ligne"]/dd'))
      stopifnot(grepl('Résumé journalier', unit, fixed = TRUE),
                !grepl('Mesure horaire', unit, fixed = TRUE))
    }
    missing <- receipt
    missing$tables <- Filter(function(table) table$path != primary$path, receipt$tables)
    stopifnot(inherits(try(dataset_primary_kit_table(meta, missing), silent = TRUE), 'try-error'))
  }
})
message('Tables principales et unités des données distribuées : vérifiées.')
