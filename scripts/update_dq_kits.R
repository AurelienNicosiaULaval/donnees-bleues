# Ajoute la documentation et le script d'acquisition aux trousses existantes.
# Les CSV, les analyses et les licences sont comparés octet par octet avant remplacement.
library(jsonlite)
library(digest)
library(zip)
source('R/utils_donnees_quebec.R')
source('R/utils_classroom.R')
registry <- dq_read_registry()
dq_validate_registry(registry)
ids <- sort(unique(unlist(lapply(registry$sources, function(x) x$dataset_ids))))
ids <- ids[file.exists(file.path('assets/classroom', paste0(ids, '.zip')))]
results <- list()
for (id in ids) {
  archive <- normalizePath(file.path('assets/classroom', paste0(id, '.zip')), mustWork = TRUE)
  receipt <- read_json(paste0(archive, '.json'))
  stopifnot(identical(classroom_sha(archive), receipt$archive_sha256))
  entries <- utils::unzip(archive, list = TRUE)$Name
  if (any(grepl('(^/|(^|/)\\.\\.(/|$))', entries))) stop('Chemin ZIP dangereux.')
  stage <- tempfile('dq-kit-'); dir.create(stage)
  utils::unzip(archive, exdir = stage)
  protected <- entries[grepl('(^datasets/.*[.]R$|[.]csv$|LICENSE|LICENCE)', entries)]
  before <- vapply(file.path(stage, protected), classroom_sha, character(1))
  dq_write_kit_resources(stage, id)
  manifest <- read_json(file.path(stage, 'provenance.json'))
  manifest$donnees_quebec <- dq_citation_records(id, registry)
  manifest$documentation_updated_on <- registry$verified_on
  write_json(manifest, file.path(stage, 'provenance.json'), pretty = TRUE, auto_unbox = TRUE)
  readme <- file.path(stage, 'LISEZ-MOI.md')
  text <- readLines(readme, warn = FALSE)
  marker <- '## Acquisition par API et citations'
  if (marker %in% text) text <- text[seq_len(match(marker, text) - 1L)]
  writeLines(c(text, '', marker, '',
    'Les références recommandées par Données Québec figurent dans CITATIONS.md. Les dates des copies utilisées dans les exercices restent celles de provenance.json.', '',
    'Pour acquérir une nouvelle source, ouvrir acquerir-donnees-quebec.R avec Internet. Une première exécution affiche les ressources; renseigner ensuite resource_id. Le script utilise DataStore lorsque la ressource est interrogeable; sinon il télécharge la ressource repérée par l’API du catalogue.', '',
    'Les nouvelles sources sont placées dans un dossier daté distinct. Elles ne remplacent pas les CSV fournis. Les transformations pédagogiques restent à appliquer avant une nouvelle analyse. Les colonnes et les valeurs de l’API peuvent différer de celles du fichier téléchargeable.'), readme)
  installer <- file.path(stage, 'installer-packages.R')
  lines <- readLines(installer, warn = FALSE)
  extra <- c('jsonlite', 'httr2', 'readr', 'digest', 'xml2')
  index <- which(grepl('^packages <-', lines))
  stopifnot(length(index) == 1L)
  original <- eval(parse(text = sub('^packages <- ', '', lines[[index]])))
  lines[[index]] <- paste0('packages <- c(', paste(sprintf('"%s"', sort(unique(c(original, extra)))), collapse = ', '), ')')
  writeLines(lines, installer)
  after <- vapply(file.path(stage, protected), classroom_sha, character(1))
  stopifnot(identical(before, after))
  files <- sort(setdiff(list.files(stage, recursive = TRUE, all.files = TRUE), 'SHA256SUMS'))
  hashes <- vapply(file.path(stage, files), classroom_sha, character(1))
  writeLines(paste(hashes, files, sep = '  '), file.path(stage, 'SHA256SUMS'))
  files <- sort(c(files, 'SHA256SUMS'))
  Sys.setFileTime(file.path(stage, files), as.POSIXct('2000-01-01', tz = 'UTC'))
  candidate <- tempfile('dq-', tmpdir = dirname(archive), fileext = '.zip')
  zip::zip(candidate, files = files, root = stage, include_directories = FALSE, mode = 'mirror')
  old_sha <- receipt$archive_sha256
  if (!file.rename(candidate, archive)) stop('Remplacement ZIP impossible : ', id)
  receipt$archive_sha256 <- classroom_sha(archive)
  receipt$archive_bytes <- unname(file.info(archive)$size)
  receipt$donnees_quebec <- dq_citation_records(id, registry)
  receipt$documentation_updated_on <- registry$verified_on
  write_json(receipt, paste0(archive, '.json'), pretty = TRUE, auto_unbox = TRUE)
  results[[id]] <- list(previous_archive_sha256 = old_sha, archive_sha256 = receipt$archive_sha256,
    protected_files_unchanged = protected, prepared_at_utc = receipt$prepared_at_utc)
  unlink(stage, recursive = TRUE)
  message(id, ' : citation et acquisition ajoutées; ', length(protected), ' fichiers conservés.')
}
dir.create('data/validation/donnees-quebec', recursive = TRUE, showWarnings = FALSE)
write_json(results, 'data/validation/donnees-quebec/trousses.json', pretty = TRUE, auto_unbox = TRUE)
