# La publication est déclarée dans chaque fiche; aucun droit n'est inféré d'un nom de licence.
validate_publication_policy <- function(metadata) {
  policy <- metadata$publication
  if (is.null(policy) || !is.logical(policy$preview) || length(policy$preview) != 1L || is.na(policy$preview)) {
    stop("Décision explicite de publication absente : ", metadata$id, call. = FALSE)
  }
  for (field in c("reason", "reviewed_on", "license_url")) {
    if (is.null(policy[[field]]) || !nzchar(as.character(policy[[field]]))) {
      stop("Champ de publication absent : ", metadata$id, " / ", field, call. = FALSE)
    }
  }
  if (isTRUE(policy$preview) && (!length(policy$preview_columns) || anyDuplicated(policy$preview_columns))) {
    stop("Liste de colonnes publiques absente ou dupliquée : ", metadata$id, call. = FALSE)
  }
  invisible(TRUE)
}

preview_path <- function(metadata) {
  if (!is.null(metadata$preview_file)) metadata$preview_file else file.path("assets/previews", paste0(metadata$id, ".csv"))
}

validate_public_preview <- function(metadata, file = preview_path(metadata)) {
  validate_publication_policy(metadata)
  if (!isTRUE(metadata$publication$preview)) {
    if (file.exists(file)) stop("Extrait publié malgré une décision négative : ", metadata$id, call. = FALSE)
    return(invisible(TRUE))
  }
  if (!file.exists(file)) stop("Extrait absent : ", metadata$id, call. = FALSE)
  data <- readr::read_csv(file, show_col_types = FALSE)
  if (nrow(data) < 2L || nrow(data) > 120L ||
      !identical(names(data), unlist(metadata$publication$preview_columns, use.names = FALSE))) {
    stop("L'extrait ne respecte pas les colonnes et la taille déclarées : ", metadata$id, call. = FALSE)
  }
  if (identical(metadata$id, "defavorisation-ecoles-primaires")) {
    private <- !is.na(data$Diffusion) & data$Diffusion == "NON"
    if (any(!is.na(data$IMSE[private])) || any(!is.na(data$SFR[private]))) {
      stop("Une valeur masquée par la source a été diffusée.", call. = FALSE)
    }
  }
  invisible(data)
}
