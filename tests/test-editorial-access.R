# The compact renderer must preserve access conditions and actual file versions.
library(xml2)
source('R/utils_dataset_page.R')
source('R/utils_catalogue_ui.R')

local({
  original_context <- dataset_current_context
  on.exit(assign('dataset_current_context', original_context, envir = .GlobalEnv))
  for (id in c('bixi', 'arbres-quebec', 'vehicules-canada-2025',
               'empress-of-ireland', 'retards-transport-collectif', 'ulaval-programmes-cours')) {
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
