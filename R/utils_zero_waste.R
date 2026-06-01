zero_waste_dimensions <- function() {
  c(
    "contexte_quebecois",
    "accessibilite_pedagogique",
    "qualite_documentaire",
    "potentiel_nettoyage",
    "potentiel_visualisation",
    "potentiel_statistique_descriptive",
    "potentiel_inference",
    "potentiel_modelisation",
    "potentiel_ethique",
    "reutilisabilite"
  )
}

as_zero_waste_vector <- function(scores) {
  dimensions <- zero_waste_dimensions()

  if (is.data.frame(scores)) {
    if (all(c("dimension", "score") %in% names(scores))) {
      values <- scores$score
      names(values) <- scores$dimension
      return(values)
    }

    if (nrow(scores) != 1L) {
      stop("Un tableau de scores doit contenir une seule ligne ou des colonnes dimension et score.", call. = FALSE)
    }

    values <- unlist(scores[1, dimensions, drop = FALSE], use.names = TRUE)
    return(values)
  }

  if (is.list(scores) && !is.data.frame(scores)) {
    return(unlist(scores, use.names = TRUE))
  }

  scores
}

validate_zero_waste_score <- function(scores, dimensions = zero_waste_dimensions()) {
  values <- as_zero_waste_vector(scores)

  if (is.null(names(values)) || any(names(values) == "")) {
    stop("Les scores doivent être nommés.", call. = FALSE)
  }

  missing_dimensions <- setdiff(dimensions, names(values))
  if (length(missing_dimensions) > 0L) {
    stop(
      "Dimensions manquantes : ",
      paste(missing_dimensions, collapse = ", "),
      call. = FALSE
    )
  }

  values <- values[dimensions]
  values <- suppressWarnings(as.numeric(values))

  if (any(is.na(values))) {
    stop("Tous les scores doivent être numériques.", call. = FALSE)
  }

  if (any(values < 0 | values > 3)) {
    stop("Chaque score doit être compris entre 0 et 3.", call. = FALSE)
  }

  values
}

interpret_zero_waste_score <- function(total) {
  if (length(total) != 1L || is.na(total)) {
    stop("Le total doit être une valeur numérique unique.", call. = FALSE)
  }

  if (total < 0 || total > 30) {
    stop("Le total doit être compris entre 0 et 30.", call. = FALSE)
  }

  if (total <= 10) {
    return("Potentiel limité ou usage très ciblé.")
  }

  if (total <= 20) {
    return("Bon jeu pour une activité.")
  }

  if (total <= 25) {
    return("Très bon jeu pour plusieurs modules.")
  }

  "Jeu structurant pour un cours ou un projet complet."
}

compute_zero_waste_score <- function(scores) {
  values <- validate_zero_waste_score(scores)
  total <- sum(values)
  max_score <- length(values) * 3

  data.frame(
    total = total,
    max_score = max_score,
    percentage = total / max_score,
    interpretation = interpret_zero_waste_score(total),
    stringsAsFactors = FALSE
  )
}

