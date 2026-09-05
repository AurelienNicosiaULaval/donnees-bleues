# Vocabulaire commun aux fiches et aux activités. Les synonymes servent à la recherche.
read_taxonomy <- function() {
  root <- getwd()
  while (!file.exists(file.path(root, "_quarto.yml"))) {
    parent <- dirname(root)
    if (identical(root, parent)) stop("Racine du projet introuvable.", call. = FALSE)
    root <- parent
  }
  yaml::read_yaml(file.path(root, "data/metadata/taxonomie.yml"))
}

taxonomy_normalize <- function(x) {
  tolower(trimws(iconv(x, to = "ASCII//TRANSLIT")))
}

taxonomy_resolve <- function(values, kind = "concepts") {
  terms <- read_taxonomy()[[kind]]
  vapply(values, function(value) {
    found <- vapply(terms, function(term) {
      taxonomy_normalize(value) %in% taxonomy_normalize(c(term$id, term$label, unlist(term$aliases)))
    }, logical(1))
    if (sum(found) != 1L) stop("Terme absent ou ambigu dans la taxonomie : ", value, call. = FALSE)
    terms[[which(found)]]$id
  }, character(1), USE.NAMES = FALSE)
}

taxonomy_search_aliases <- function(ids) {
  terms <- read_taxonomy()$concepts
  selected <- Filter(function(term) term$id %in% ids, terms)
  paste(unique(unlist(lapply(selected, function(term) c(term$label, term$aliases)))), collapse = "; ")
}

validate_taxonomy_metadata <- function(metadata) {
  ids <- taxonomy_resolve(unlist(metadata$concepts))
  if (!identical(ids, unname(unlist(metadata$concept_ids)))) {
    stop("Les identifiants des concepts ne correspondent pas à leurs libellés : ", metadata$id, call. = FALSE)
  }
  allowed_levels <- vapply(read_taxonomy()$levels, `[[`, character(1), "id")
  if (!length(metadata$level_ids) || !all(unlist(metadata$level_ids) %in% allowed_levels)) {
    stop("Niveaux canoniques invalides : ", metadata$id, call. = FALSE)
  }
  invisible(TRUE)
}
